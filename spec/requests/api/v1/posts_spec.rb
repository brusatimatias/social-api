require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  describe "GET /api/v1/posts" do
    it "lists posts" do
      get api_v1_posts_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |post| post["content"] }).to include(posts(:one).content)
      post = response.parsed_body["data"].find { |item| item["id"] == posts(:one).id }
      expect(post["comments_count"]).to eq(1)
      expect(post["likes_count"]).to eq(1)
      expect(response.parsed_body["meta"]["statuses"]).to eq(Post.statuses.keys)
    end

    it "filters posts by status" do
      get api_v1_posts_path, params: { status: "draft" }, headers: auth_headers(users(:two))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |post| post["id"] }).to eq([posts(:two).id])
      expect(response.parsed_body["data"].first["comments_count"]).to eq(1)
      expect(response.parsed_body["data"].first["likes_count"]).to eq(1)
    end

    it "rejects an invalid status filter" do
      get api_v1_posts_path, params: { status: "invalid" }, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["data"]).to be_nil
      expect(response.parsed_body["errors"]).to eq(
        ["Invalid status. Allowed values: #{Post.statuses.keys.join(", ")}"]
      )
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
      expect(response.parsed_body["data"]["content"]).to eq("A new post")
      expect(response.parsed_body["data"]["user_id"]).to eq(users(:one).id)
      expect(response.parsed_body["data"]["visibility"]).to eq("public")
      expect(response.parsed_body["data"]["status"]).to eq("published")
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

    it "rejects an invalid visibility instead of raising" do
      expect do
        post api_v1_posts_path, params: {
          post: { content: "A new post", visibility: "invalid" }
        }, headers: auth_headers, as: :json
      end.not_to change(Post, :count)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to eq(["'invalid' is not a valid visibility"])
    end

    it "creates a post with a media attachment and returns its URL" do
      expect do
        post api_v1_posts_path, params: {
          post: { content: "A post with a photo", media: [fixture_file_upload("avatar.png", "image/png")] }
        }, headers: auth_headers
      end.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["media"].size).to eq(1)
      expect(response.parsed_body["data"]["media"].first).to match(%r{\Ahttp://})
    end

    it "rejects a post with an unsupported media type" do
      expect do
        post api_v1_posts_path, params: {
          post: {
            content: "A post with a bad file",
            media: [fixture_file_upload("document.txt", "text/plain")]
          }
        }, headers: auth_headers
      end.not_to change(Post, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).not_to be_empty
    end
  end

  describe "resource actions" do
    it "shows a post" do
      get api_v1_post_path(posts(:one).id), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["content"]).to eq(posts(:one).content)
      expect(response.parsed_body["data"]["comments"].map { |comment| comment["content"] })
        .to include(comments(:one).content)
      comment = response.parsed_body["data"]["comments"].find { |item| item["id"] == comments(:one).id }
      expect(comment["user"]["id"]).to eq(users(:two).id)
      expect(comment["user"]["name"]).to eq(users(:two).name)
      expect(comment["user"]).not_to have_key("password_digest")

      like = response.parsed_body["data"]["likes"].find { |item| item["id"] == likes(:one).id }
      expect(like["user"]["id"]).to eq(users(:two).id)
      expect(like["user"]).not_to have_key("password_digest")
      expect(like["user"]["name"]).to eq(users(:two).name)
    end

    it "returns a standard error for an unknown post" do
      get api_v1_post_path(-1), headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["errors"]).to eq(["Resource not found"])
    end

    it "shows another user's public post" do
      get api_v1_post_path(posts(:one).id), headers: auth_headers(users(:three))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["content"]).to eq(posts(:one).content)
    end

    it "hides a draft post from a non-owner even when they follow the author" do
      get api_v1_post_path(posts(:two).id), headers: auth_headers(users(:one))

      expect(response).to have_http_status(:not_found)
    end

    it "shows a published followers-only post to a follower" do
      get api_v1_post_path(posts(:two_followers).id), headers: auth_headers(users(:one))

      expect(response).to have_http_status(:ok)
    end

    it "hides a published followers-only post from a non-follower" do
      get api_v1_post_path(posts(:two_followers).id), headers: auth_headers(users(:three))

      expect(response).to have_http_status(:not_found)
    end

    it "hides a published private post from anyone but the owner" do
      get api_v1_post_path(posts(:two_private).id), headers: auth_headers(users(:one))

      expect(response).to have_http_status(:not_found)
    end

    it "updates a post" do
      patch api_v1_post_path(posts(:one).id), params: {
        post: { content: "An updated post", visibility: "private", status: "archived" }
      }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["content"]).to eq("An updated post")
      expect(response.parsed_body["data"]["visibility"]).to eq("private")
      expect(response.parsed_body["data"]["status"]).to eq("archived")
      expect(response.parsed_body["data"]["edited_at"]).not_to be_nil
    end

    it "rejects an invalid status instead of raising" do
      patch api_v1_post_path(posts(:one).id), params: {
        post: { status: "invalid" }
      }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to eq(["'invalid' is not a valid status"])
    end

    it "rejects updating a post that belongs to someone else" do
      patch api_v1_post_path(posts(:one).id), params: {
        post: { content: "Hijacked" }
      }, headers: auth_headers(users(:two)), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "rejects deleting a post that belongs to someone else" do
      expect do
        delete api_v1_post_path(posts(:one).id), headers: auth_headers(users(:two))
      end.not_to change(Post, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "soft-deletes a post instead of destroying it" do
      expect do
        delete api_v1_post_path(posts(:one).id), headers: auth_headers
      end.to change(Post, :count).by(-1) # hidden from normal queries, not actually destroyed

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(posts(:one).id)
      expect(posts(:one).reload.deleted_at).to be_present
      expect(Post.with_deleted.exists?(posts(:one).id)).to be true
    end

    it "hides a soft-deleted post from its owner afterwards" do
      delete api_v1_post_path(posts(:one).id), headers: auth_headers

      get api_v1_post_path(posts(:one).id), headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "excludes a soft-deleted post from the index" do
      delete api_v1_post_path(posts(:one).id), headers: auth_headers

      get api_v1_posts_path, headers: auth_headers

      expect(response.parsed_body["data"].map { |post| post["id"] }).not_to include(posts(:one).id)
    end
  end
end
