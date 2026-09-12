require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    it "lists users without exposing password digest" do
      get api_v1_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("password_digest")
    end
  end

  describe "POST /api/v1/users" do
    it "creates a user" do
      expect do
        post api_v1_users_path, params: {
          user: {
            name: "Katherine",
            lastname: "Johnson",
            email: "katherine@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }, as: :json
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to eq("katherine@example.com")
      expect(response.parsed_body).not_to have_key("password_digest")
    end

    it "rejects an invalid user" do
      expect do
        post api_v1_users_path, params: { user: { email: "invalid" } }, as: :json
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "shows a user by uuid" do
      get api_v1_user_path(users(:one).uuid)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["email"]).to eq(users(:one).email)
    end

    it "updates a user" do
      patch api_v1_user_path(users(:one).uuid), params: { user: { name: "Augusta" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Augusta")
    end

    it "deletes a user" do
      expect do
        delete api_v1_user_path(users(:one).uuid)
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
