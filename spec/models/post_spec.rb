require "rails_helper"

RSpec.describe Post, type: :model do
  it "is valid with content and a user" do
    expect(posts(:one)).to be_valid
  end

  it "requires content" do
    post = Post.new(user: users(:one))

    expect(post).not_to be_valid
    expect(post.errors[:content]).to include("can't be blank")
  end

  it "uses public visibility and published status by default" do
    post = Post.new(content: "A post", user: users(:one))

    expect(post).to be_valid
    expect(post).to be_visibility_public
    expect(post).to be_published
  end

  it "defines visibility and status values through enums" do
    expect(Post.visibilities).to eq(
      "public" => "public",
      "followers" => "followers",
      "private" => "private"
    )
    expect(Post.statuses).to eq(
      "draft" => "draft",
      "published" => "published",
      "archived" => "archived"
    )
  end

  it "sets edited_at when content changes" do
    post = posts(:one)

    expect { post.update!(content: "An edited post") }.to change(post, :edited_at)
  end

  it "belongs to a user" do
    expect(posts(:one).user).to eq(users(:one))
  end

  it "includes comment and like counts" do
    post = users(:one).posts.with_counts.find(posts(:one).id)

    expect(post.comments_count).to eq(1)
    expect(post.likes_count).to eq(1)
  end

  it "filters by status when provided" do
    expect(users(:two).posts.for_status("draft")).to contain_exactly(posts(:two))
  end

  describe "#destroy" do
    it "sets deleted_at instead of destroying the record" do
      post = posts(:one)

      expect { post.destroy }.to change(post, :deleted_at).from(nil)
      expect(Post.with_deleted.exists?(post.id)).to be true
    end
  end

  describe "default_scope" do
    it "excludes soft-deleted posts from normal queries, including through associations" do
      posts(:one).destroy

      expect(Post.all).not_to include(posts(:one))
      expect(users(:one).posts).not_to include(posts(:one))
      expect(Post.find_by(id: posts(:one).id)).to be_nil
    end

    it "still finds a soft-deleted post via .with_deleted" do
      posts(:one).destroy

      expect(Post.with_deleted).to include(posts(:one))
    end

    it "only returns soft-deleted posts via .only_deleted" do
      posts(:one).destroy

      expect(Post.only_deleted).to contain_exactly(posts(:one))
    end
  end

  describe ".visible_to" do
    it "excludes a soft-deleted post even if it would otherwise be visible" do
      posts(:one).destroy

      expect(Post.visible_to(users(:one))).not_to include(posts(:one))
    end
  end

  describe "media" do
    def attach(post, filename, content_type)
      post.media.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/#{filename}")),
        filename: filename,
        content_type: content_type
      )
    end

    it "is valid with an allowed media type" do
      post = Post.new(content: "A post with an image", user: users(:one))
      attach(post, "avatar.png", "image/png")

      expect(post).to be_valid
    end

    it "rejects an unsupported media type" do
      post = Post.new(content: "A post with a bad attachment", user: users(:one))
      attach(post, "document.txt", "text/plain")

      expect(post).not_to be_valid
      expect(post.errors[:media]).to include(/unsupported content type/)
    end

    it "rejects more than the maximum number of files" do
      post = Post.new(content: "Too much media", user: users(:one))
      (Post::MAX_MEDIA_FILES + 1).times { attach(post, "avatar.png", "image/png") }

      expect(post).not_to be_valid
      expect(post.errors[:media]).to include("can have at most #{Post::MAX_MEDIA_FILES} files")
    end

    it "rejects a file over the size limit" do
      stub_const("Post::MAX_MEDIA_SIZE", 10)
      post = Post.new(content: "A post with a huge file", user: users(:one))
      attach(post, "avatar.png", "image/png")

      expect(post).not_to be_valid
      expect(post.errors[:media]).to include(/exceeds the 0MB size limit/)
    end

    it "serializes media as absolute URLs" do
      post = posts(:one)
      attach(post, "avatar.png", "image/png")
      post.save!

      expect(post.as_json["media"]).to all(match(%r{\Ahttp://}))
    end
  end
end
