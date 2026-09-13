class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many_attached :media

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

  validates :content, presence: true
  validates :visibility, inclusion: { in: %w[public followers private] }
  validates :status, inclusion: { in: %w[draft published archived] }

  before_update :set_edited_at, if: :content_changed?

  private

  def set_edited_at
    self.edited_at = Time.current
  end
end
