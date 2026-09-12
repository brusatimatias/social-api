require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    it "requires authentication" do
      get api_v1_users_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists users without exposing password digest" do
      get api_v1_users_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("password_digest")
    end
  end

  describe "resource actions" do
    it "shows a user by uuid" do
      get api_v1_user_path(users(:one).uuid), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["email"]).to eq(users(:one).email)
    end

    it "updates a user" do
      patch api_v1_user_path(users(:one).uuid), params: { user: { name: "Augusta" } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Augusta")
    end

    it "deletes a user" do
      expect do
        delete api_v1_user_path(users(:one).uuid), headers: auth_headers
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(users(:one).id)
    end
  end
end
