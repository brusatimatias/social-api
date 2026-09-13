class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many_attached :media

  enum :visibility, { public: "public", followers: "followers", private: "private" }, prefix: true
  enum :status, { draft: "draft", published: "published", archived: "archived" }

  scope :with_counts, lambda {
    left_joins(:comments, :likes)
      .select(
        "posts.*",
        "COUNT(DISTINCT comments.id) AS comments_count",
        "COUNT(DISTINCT likes.id) AS likes_count"
      )
      .group("posts.id")
  }
  scope :for_status, ->(status) { status.present? ? where(status:) : all }
  scope :visible_to, lambda { |user|
    where(user_id: user.id)
      .or(where(status: statuses[:published], visibility: visibilities[:public]))
      .or(where(
        status: statuses[:published],
        visibility: visibilities[:followers],
        user_id: user.following.select(:id)
      ))
  }

  validates :content, presence: true

  before_update :set_edited_at, if: :content_changed?

  private

  def set_edited_at
    self.edited_at = Time.current
  end
end
