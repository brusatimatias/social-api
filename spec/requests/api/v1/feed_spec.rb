require "rails_helper"

RSpec.describe "Api::V1::Feed", type: :request do
  describe "GET /api/v1/feed" do
    it "returns published visible posts from followed users with relationships and counts" do
      get api_v1_feed_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.map { |post| post["id"] }).to eq([posts(:two_public).id, posts(:two_followers).id])
      expect(data.first["comments_count"]).to eq(1)
      expect(data.first["likes_count"]).to eq(1)
      expect(data.first["comments"].first["user"]["name"]).to eq(users(:two).name)
      expect(data.first["likes"].first["user"]["name"]).to eq(users(:two).name)
      expect(response.parsed_body["meta"]).to include(
        "current_page" => 1,
        "per_page" => Posts::FeedQuery::DEFAULT_PER_PAGE,
        "total_pages" => 1,
        "total_count" => 2
      )
    end

    it "paginates the feed" do
      get api_v1_feed_path, params: { page: 2, per_page: 1 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |post| post["id"] }).to eq([posts(:two_followers).id])
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
