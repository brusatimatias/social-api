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
      expect(response.parsed_body["token"]).to be_present
      expect(response.parsed_body["user"]["email"]).to eq("new.user@example.com")
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
      expect(response.parsed_body["token"]).to be_present
    end

    it "rejects invalid credentials" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "wrong" }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the authenticated user" do
      post api_v1_auth_login_path, params: {
        auth: { email: users(:one).email, password: "password" }
      }, as: :json
      token = response.parsed_body["token"]

      get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["email"]).to eq(users(:one).email)
    end

    it "updates the authenticated user" do
      patch api_v1_auth_me_path, params: { user: { name: "Augusta" } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Augusta")
    end

    it "deletes the authenticated user" do
      expect do
        delete api_v1_auth_me_path, headers: auth_headers
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(users(:one).id)
    end

    it "rejects requests without a valid token" do
      get api_v1_auth_me_path

      expect(response).to have_http_status(:unauthorized)
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
