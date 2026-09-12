require "rails_helper"

RSpec.describe "Api::V1::Comments", type: :request do
  describe "GET /api/v1/posts/:post_id/comments" do
    it "lists comments" do
      get api_v1_post_comments_path(posts(:one).id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |comment| comment["content"] })
        .to include(comments(:one).content)
    end
  end

  describe "POST /api/v1/posts/:post_id/comments" do
    it "creates a comment" do
      expect do
        post api_v1_post_comments_path(posts(:one).id), params: {
          comment: { content: "A new comment" }
        }, headers: auth_headers, as: :json
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["content"]).to eq("A new comment")
      expect(response.parsed_body["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["post_id"]).to eq(posts(:one).id)
    end

    it "rejects a comment without content" do
      expect do
        post api_v1_post_comments_path(posts(:one).id), params: {
          comment: { content: nil }
        }, headers: auth_headers, as: :json
      end.not_to change(Comment, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "updates a comment" do
      patch api_v1_post_comment_path(posts(:one).id, comments(:one).id), params: {
        comment: { content: "An updated comment" }
      }, headers: auth_headers(users(:two)), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("An updated comment")
    end

    it "deletes a comment" do
      expect do
        delete api_v1_post_comment_path(posts(:one).id, comments(:one).id), headers: auth_headers(users(:two))
      end.to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
