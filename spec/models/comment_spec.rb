require "rails_helper"

RSpec.describe Comment, type: :model do
  it "is valid with content, a user, and a post" do
    expect(comments(:one)).to be_valid
  end

  it "requires content" do
    comment = Comment.new(user: users(:one), post: posts(:one))

    expect(comment).not_to be_valid
    expect(comment.errors[:content]).to include("can't be blank")
  end

  it "belongs to a user and a post" do
    comment = comments(:one)

    expect(comment.user).to eq(users(:two))
    expect(comment.post).to eq(posts(:one))
  end
end
