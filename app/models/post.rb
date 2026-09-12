class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many_attached :media

  validates :content, presence: true
  validates :visibility, inclusion: { in: %w[public followers private] }
  validates :status, inclusion: { in: %w[draft published archived] }

  before_update :set_edited_at, if: :content_changed?

  private

  def set_edited_at
    self.edited_at = Time.current
  end
end
