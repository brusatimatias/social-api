require "rails_helper"

RSpec.describe "Api::V1::Comments", type: :request do
  describe "GET /api/v1/comments" do
    it "lists comments" do
      get api_v1_comments_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |comment| comment["content"] })
        .to include(comments(:one).content)
    end
  end

  describe "POST /api/v1/comments" do
    it "creates a comment" do
      expect do
        post api_v1_comments_path, params: {
          comment: {
            content: "A new comment",
            user_id: users(:one).id,
            post_id: posts(:one).id
          }
        }, as: :json
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["content"]).to eq("A new comment")
      expect(response.parsed_body["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["post_id"]).to eq(posts(:one).id)
    end

    it "rejects a comment without content" do
      expect do
        post api_v1_comments_path, params: {
          comment: { user_id: users(:one).id, post_id: posts(:one).id }
        }, as: :json
      end.not_to change(Comment, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "shows a comment" do
      get api_v1_comment_path(comments(:one).id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq(comments(:one).content)
    end

    it "updates a comment" do
      patch api_v1_comment_path(comments(:one).id), params: {
        comment: { content: "An updated comment" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("An updated comment")
    end

    it "deletes a comment" do
      expect do
        delete api_v1_comment_path(comments(:one).id)
      end.to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
