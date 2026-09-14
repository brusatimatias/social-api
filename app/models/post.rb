class Post < ApplicationRecord
  MAX_MEDIA_FILES = 4
  MAX_MEDIA_SIZE = 10.megabytes
  ALLOWED_MEDIA_TYPES = %w[image/png image/jpeg image/webp image/gif video/mp4 video/quicktime].freeze

  belongs_to :user
  # No `dependent: :destroy` here: paranoia's soft `destroy` still runs Rails' own dependent-destroy
  # callbacks, which would really delete non-paranoid records. Comments/likes are left in place
  # (still pointing at the now soft-deleted post) so a post's history survives its own deletion.
  has_many :comments
  has_many :likes
  has_many_attached :media

  enum :visibility, { public: "public", followers: "followers", private: "private" }, prefix: true
  enum :status, { draft: "draft", published: "published", archived: "archived" }

  # Adds `destroy` (soft, sets deleted_at), `really_destroy!` (hard delete), `restore`/`restore!`,
  # the default_scope that hides soft-deleted posts everywhere, and `.with_deleted`/`.only_deleted`.
  acts_as_paranoid

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
  validate :media_within_limits

  before_update :set_edited_at, if: :content_changed?

  def as_json(options = {})
    super(options).merge("media" => media_urls, "author" => author_json)
  end

  private

  def author_json
    { "uuid" => user.uuid, "id" => user.id, "name" => user.name, "lastname" => user.lastname }
  end

  def media_urls
    media.map do |file|
      Rails.application.routes.url_helpers.rails_blob_url(file, **ActiveStorage::Current.url_options.to_h)
    end
  end

  def media_within_limits
    return if media.blank?

    errors.add(:media, "can have at most #{MAX_MEDIA_FILES} files") if media.size > MAX_MEDIA_FILES

    media.each do |file|
      next unless file.blob

      unless file.blob.content_type.in?(ALLOWED_MEDIA_TYPES)
        errors.add(:media, "#{file.blob.filename} has an unsupported content type")
      end

      if file.blob.byte_size > MAX_MEDIA_SIZE
        errors.add(:media, "#{file.blob.filename} exceeds the #{MAX_MEDIA_SIZE / 1.megabyte}MB size limit")
      end
    end
  end

  def set_edited_at
    self.edited_at = Time.current
  end
end
