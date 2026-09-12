require "rails_helper"

RSpec.describe "Api::V1::Likes", type: :request do
  describe "POST /api/v1/posts/:post_id/likes" do
    it "creates a like" do
      expect do
        post api_v1_post_likes_path(posts(:one).id), headers: auth_headers, as: :json
      end.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["post_id"]).to eq(posts(:one).id)
    end

    it "rejects a duplicate like" do
      Like.create!(user: users(:one), post: posts(:one))

      expect do
        post api_v1_post_likes_path(posts(:one).id), headers: auth_headers, as: :json
      end.not_to change(Like, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "deletes a like" do
      expect do
        delete api_v1_post_like_path(posts(:one).id, likes(:one).id), headers: auth_headers
      end.to change(Like, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(likes(:one).id)
    end
  end
end
