require "rails_helper"

RSpec.describe "Api::V1::Likes", type: :request do
  describe "GET /api/v1/likes" do
    it "lists likes" do
      get api_v1_likes_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |like| like["id"] }).to include(likes(:one).id)
    end
  end

  describe "POST /api/v1/likes" do
    it "creates a like" do
      expect do
        post api_v1_likes_path, params: {
          like: { user_id: users(:one).id, post_id: posts(:one).id }
        }, as: :json
      end.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["post_id"]).to eq(posts(:one).id)
    end

    it "rejects a duplicate like" do
      expect do
        post api_v1_likes_path, params: {
          like: { user_id: users(:two).id, post_id: posts(:one).id }
        }, as: :json
      end.not_to change(Like, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "shows a like" do
      get api_v1_like_path(likes(:one).id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(likes(:one).id)
    end

    it "deletes a like" do
      expect do
        delete api_v1_like_path(likes(:one).id)
      end.to change(Like, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
