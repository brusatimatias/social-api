require "rails_helper"

RSpec.describe "Api::V1::Authentication", type: :request do
  describe "POST /api/v1/auth/register" do
    it "registers a user and returns a token" do
      expect do
        post api_v1_auth_register_path, params: {
          user: {
            name: "Katherine",
            lastname: "Johnson",
            email: "new.user@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }, as: :json
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["token"]).to be_present
      expect(response.parsed_body["data"]["user"]["email"]).to eq("new.user@example.com")
    end

    it "rejects invalid data" do
      expect do
        post api_v1_auth_register_path, params: {
          user: { email: "invalid" }
        }, as: :json
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "POST /api/v1/auth/login" do
    it "authenticates valid credentials" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["token"]).to be_present
    end

    it "rejects invalid credentials" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "wrong" }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"]).to eq(["Invalid email or password"])
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "revokes the current token" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json
      token = response.parsed_body["data"]["token"]

      expect do
        delete api_v1_auth_logout_path, headers: { "Authorization" => "Bearer #{token}" }
      end.to change(RevokedToken, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "rejects reusing a token after logout" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json
      token = response.parsed_body["data"]["token"]

      delete api_v1_auth_logout_path, headers: { "Authorization" => "Bearer #{token}" }
      get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"]).to eq(["Unauthorized"])
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the authenticated user" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json
      token = response.parsed_body["data"]["token"]

      get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["email"]).to eq(users(:one).email)
    end

    it "updates the authenticated user" do
      patch api_v1_auth_me_path, params: { user: { name: "Augusta" } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Augusta")
    end

    it "deactivates the authenticated user instead of destroying it" do
      expect do
        delete api_v1_auth_me_path, headers: auth_headers
      end.to change(User, :count).by(-1) # hidden from normal queries, not actually destroyed

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(users(:one).id)
      expect(users(:one).reload.deleted_at).to be_present
      expect(User.with_deleted.exists?(users(:one).id)).to be true
    end

    it "also soft-deletes the deactivated user's own posts" do
      delete api_v1_auth_me_path, headers: auth_headers

      expect(posts(:one).reload.deleted_at).to be_present
    end

    it "rejects logging in as a deactivated user" do
      delete api_v1_auth_me_path, headers: auth_headers

      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects further requests with the deactivated user's existing token" do
      token = auth_headers["Authorization"]
      delete api_v1_auth_me_path, headers: { "Authorization" => token }

      get api_v1_auth_me_path, headers: { "Authorization" => token }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows a new registration to reuse a deactivated user's email" do
      delete api_v1_auth_me_path, headers: auth_headers

      expect do
        post api_v1_auth_register_path, params: {
          user: {
            name: "New",
            lastname: "Owner",
            email: users(:one).email,
            password: "password",
            password_confirmation: "password"
          }
        }, as: :json
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "rejects requests without a valid token" do
      get api_v1_auth_me_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"]).to eq(["Unauthorized"])
    end

    it "rejects an expired token" do
      token = JWT.encode(
        { sub: users(:one).id, exp: 1.minute.ago.to_i },
        Rails.application.secret_key_base,
        "HS256"
      )

      get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
