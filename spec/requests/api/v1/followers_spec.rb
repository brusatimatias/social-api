require "rails_helper"

RSpec.describe "Api::V1::Followers", type: :request do
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
