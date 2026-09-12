require "rails_helper"

RSpec.describe "Api::V1::Followers", type: :request do
  describe "POST /api/v1/followers" do
    it "creates a follower relationship" do
      expect do
        post api_v1_followers_path, params: {
          follower: { follower_id: users(:three).id, following_id: users(:one).id }
        }, as: :json
      end.to change(Follower, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["follower_id"]).to eq(users(:three).id)
      expect(response.parsed_body["following_id"]).to eq(users(:one).id)
    end

    it "rejects self-following" do
      expect do
        post api_v1_followers_path, params: {
          follower: { follower_id: users(:one).id, following_id: users(:one).id }
        }, as: :json
      end.not_to change(Follower, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "DELETE /api/v1/followers/:id" do
    it "deletes a follower relationship" do
      expect do
        delete api_v1_follower_path(followers(:one).id)
      end.to change(Follower, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
