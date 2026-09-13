require "rails_helper"

RSpec.describe "Api::V1::Feed", type: :request do
  describe "GET /api/v1/feed" do
    it "returns published visible posts from followed users with relationships and counts" do
      followed_post = Post.create!(
        content: "A followed post",
        user: users(:two),
        visibility: "followers",
        status: "published",
        created_at: 2.days.ago
      )
      public_post = Post.create!(
        content: "A public followed post",
        user: users(:two),
        visibility: "public",
        status: "published",
        created_at: 1.day.ago
      )
      Post.create!(content: "A private post", user: users(:two), visibility: "private", status: "published")
      Post.create!(content: "A draft post", user: users(:two), visibility: "public", status: "draft")
      Comment.create!(content: "A comment", user: users(:two), post: public_post)
      Like.create!(user: users(:two), post: public_post)

      get api_v1_feed_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.map { |post| post["id"] }).to eq([public_post.id, followed_post.id])
      expect(data.first["comments_count"]).to eq(1)
      expect(data.first["likes_count"]).to eq(1)
      expect(data.first["comments"].first["user"]["name"]).to eq(users(:two).name)
      expect(data.first["likes"].first["user"]["name"]).to eq(users(:two).name)
    end

    it "paginates the feed" do
      2.times do |index|
        Post.create!(
          content: "Feed post #{index}",
          user: users(:two),
          visibility: "public",
          status: "published"
        )
      end

      get api_v1_feed_path, params: { page: 2, per_page: 1 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["meta"]).to include(
        "current_page" => 2,
        "per_page" => 1,
        "total_pages" => 2,
        "total_count" => 2
      )
    end

    it "rejects invalid pagination values" do
      get api_v1_feed_path, params: { page: 0, per_page: 100 }, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to eq(
        ["Pagination values must be positive integers and per_page cannot exceed 50"]
      )
    end
  end
end
