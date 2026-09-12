require "rails_helper"

RSpec.describe "Api::V1::Followers", type: :request do
  describe "GET /api/v1/users/followers" do
    it "lists the authenticated user's followers" do
      get followers_api_v1_users_path, headers: auth_headers(users(:one))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |user| user["id"] }).to include(users(:two).id)
    end

    it "lists another user's followers by user_id" do
      get followers_api_v1_users_path, params: { user_id: users(:one).uuid }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |user| user["id"] }).to include(users(:two).id)
    end
  end

  describe "GET /api/v1/users/following" do
    it "lists the authenticated user's following" do
      get following_api_v1_users_path, headers: auth_headers(users(:one))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |user| user["id"] }).to include(users(:two).id)
    end

    it "lists another user's following by user_id" do
      get following_api_v1_users_path, params: { user_id: users(:one).uuid }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |user| user["id"] }).to include(users(:two).id)
    end
  end

  describe "POST /api/v1/users/:id/follow" do
    it "creates a follower relationship" do
      expect do
        post follow_api_v1_user_path(users(:one).uuid), headers: auth_headers(users(:three)), as: :json
      end.to change(Follower, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["follower_id"]).to eq(users(:three).id)
      expect(response.parsed_body["following_id"]).to eq(users(:one).id)
    end

    it "rejects self-following" do
      expect do
        post follow_api_v1_user_path(users(:one).uuid), headers: auth_headers, as: :json
      end.not_to change(Follower, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "DELETE /api/v1/users/:id/follow" do
    it "deletes a follower relationship" do
      expect do
        delete follow_api_v1_user_path(users(:two).uuid), headers: auth_headers(users(:one))
      end.to change(Follower, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
