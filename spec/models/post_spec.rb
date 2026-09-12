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
    expect(post.visibility).to eq("public")
    expect(post.status).to eq("published")
  end

  it "sets edited_at when content changes" do
    post = posts(:one)

    expect { post.update!(content: "An edited post") }.to change(post, :edited_at)
  end

  it "belongs to a user" do
    expect(posts(:one).user).to eq(users(:one))
  end
end
