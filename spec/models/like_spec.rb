require "rails_helper"

RSpec.describe Like, type: :model do
  it "is valid with a user and a post" do
    expect(likes(:one)).to be_valid
  end

  it "belongs to a user and a post" do
    like = likes(:one)

    expect(like.user).to eq(users(:two))
    expect(like.post).to eq(posts(:one))
  end

  it "prevents a user from liking the same post twice" do
    like = Like.new(user: users(:two), post: posts(:one))

    expect(like).not_to be_valid
    expect(like.errors[:user_id]).to include("has already been taken")
  end
end
