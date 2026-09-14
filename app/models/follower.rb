class Follower < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :following_relationships
  belongs_to :following, class_name: "User", inverse_of: :follower_relationships

  validates :follower_id, uniqueness: { scope: :following_id }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:following_id, "can't be the same as follower") if follower_id == following_id
  end
end
