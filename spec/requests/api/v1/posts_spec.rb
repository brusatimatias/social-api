require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  describe "GET /api/v1/posts" do
    it "lists posts" do
      get api_v1_posts_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |post| post["content"] }).to include(posts(:one).content)
      expect(response.parsed_body.first).to have_key("comments")
      expect(response.parsed_body.first).to have_key("likes")
    end

    it "filters posts by status" do
      get api_v1_posts_path, params: { status: "draft" }, headers: auth_headers(users(:two))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |post| post["id"] }).to eq([posts(:two).id])
    end
  end

  describe "POST /api/v1/posts" do
    it "creates a post" do
      expect do
        post api_v1_posts_path, params: {
          post: { content: "A new post" }
        }, headers: auth_headers, as: :json
      end.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["content"]).to eq("A new post")
      expect(response.parsed_body["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["visibility"]).to eq("public")
      expect(response.parsed_body["status"]).to eq("published")
    end

    it "rejects a post without content" do
      expect do
        post api_v1_posts_path, params: {
          post: { content: nil }
        }, headers: auth_headers, as: :json
      end.not_to change(Post, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "shows a post" do
      get api_v1_post_path(posts(:one).id), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq(posts(:one).content)
      expect(response.parsed_body["comments"].map { |comment| comment["content"] })
        .to include(comments(:one).content)
      expect(response.parsed_body["likes"].map { |like| like["id"] }).to include(likes(:one).id)
    end

    it "updates a post" do
      patch api_v1_post_path(posts(:one).id), params: {
        post: { content: "An updated post", visibility: "private", status: "archived" }
      }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("An updated post")
      expect(response.parsed_body["visibility"]).to eq("private")
      expect(response.parsed_body["status"]).to eq("archived")
      expect(response.parsed_body["edited_at"]).not_to be_nil
    end

    it "deletes a post" do
      expect do
        delete api_v1_post_path(posts(:one).id), headers: auth_headers
      end.to change(Post, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(posts(:one).id)
    end
  end
end
