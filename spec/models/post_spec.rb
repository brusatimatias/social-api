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
end
