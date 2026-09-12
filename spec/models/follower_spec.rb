require "rails_helper"

RSpec.describe Follower, type: :model do
  it "is valid when one user follows another" do
    expect(followers(:one)).to be_valid
  end

  it "prevents self-following" do
    follower = Follower.new(follower: users(:one), following: users(:one))

    expect(follower).not_to be_valid
    expect(follower.errors[:following_id]).to include("can't be the same as follower")
  end

  it "prevents duplicate relationships" do
    follower = Follower.new(follower: users(:one), following: users(:two))

    expect(follower).not_to be_valid
    expect(follower.errors[:follower_id]).to include("has already been taken")
  end

  it "exposes following and followers through User" do
    expect(users(:one).following).to include(users(:two))
    expect(users(:two).followers).to include(users(:one))
  end
end
