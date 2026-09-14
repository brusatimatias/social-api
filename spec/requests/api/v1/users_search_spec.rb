require "rails_helper"

RSpec.describe "Api::V1::Users search", type: :request do
  describe "GET /api/v1/users/search" do
    it "matches by name, lastname or email, excluding the current user" do
      get search_api_v1_users_path, params: { q: "grace" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |user| user["id"] }).to eq([users(:two).id])
    end

    it "matches case-insensitively against a partial term" do
      get search_api_v1_users_path, params: { q: "HOP" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |user| user["id"] }).to eq([users(:two).id])
    end

    it "matches by email" do
      get search_api_v1_users_path, params: { q: "katherine@example.com" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |user| user["id"] }).to eq([users(:three).id])
    end

    it "never includes the requesting user" do
      get search_api_v1_users_path, params: { q: "ada" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_empty
    end

    it "returns all other users ordered by most recent when q is blank" do
      older = User.create!(
        name: "Older", lastname: "Person", email: "older@example.com", password: "password"
      )
      older.update_column(:created_at, 2.days.ago)
      newer = User.create!(
        name: "Newer", lastname: "Person", email: "newer@example.com", password: "password"
      )
      newer.update_column(:created_at, 1.hour.ago)

      get search_api_v1_users_path, params: { per_page: 50 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["data"].map { |user| user["id"] }
      expect(ids.index(newer.id)).to be < ids.index(older.id)
      expect(response.parsed_body["meta"]).to include(
        "current_page" => 1,
        "per_page" => 50,
        "total_count" => User.where.not(id: users(:one).id).count
      )
    end

    it "paginates results" do
      get search_api_v1_users_path, params: { q: "example.com", page: 2, per_page: 1 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |user| user["id"] }).to eq([users(:three).id])
      expect(response.parsed_body["meta"]).to include(
        "current_page" => 2,
        "per_page" => 1,
        "total_pages" => 2,
        "total_count" => 2
      )
    end

    it "excludes the password digest and includes full_name" do
      get search_api_v1_users_path, params: { q: "grace" }, headers: auth_headers

      user = response.parsed_body["data"].first
      expect(user).not_to have_key("password_digest")
      expect(user["full_name"]).to eq(users(:two).full_name)
    end

    it "rejects invalid pagination values" do
      get search_api_v1_users_path, params: { page: 0, per_page: 100 }, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to eq(
        ["Pagination values must be positive integers and per_page cannot exceed 50"]
      )
    end
  end
end
