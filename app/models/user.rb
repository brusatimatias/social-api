class User < ApplicationRecord
  AVATAR_MAX_SIZE = 5.megabytes
  AVATAR_ALLOWED_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze

  has_one_attached :avatar

  # dependent: :destroy on posts cascades as a soft-delete since Post is also acts_as_paranoid.
  # Comments/likes deliberately have no `dependent:` option (see Post) so deactivating an account
  # doesn't really delete their content. Followers/revoked_tokens are fine to hard-delete: they're
  # graph edges and session bookkeeping, not content worth auditing.
  has_many :posts, dependent: :destroy
  has_many :comments
  has_many :likes
  has_many :following_relationships, class_name: "Follower",
                                     foreign_key: :follower_id,
                                     dependent: :destroy,
                                     inverse_of: :follower
  has_many :following, through: :following_relationships, source: :following
  has_many :follower_relationships, class_name: "Follower",
                                     foreign_key: :following_id,
                                     dependent: :destroy,
                                     inverse_of: :following
  has_many :followers, through: :follower_relationships, source: :follower
  has_many :revoked_tokens, dependent: :destroy
  has_secure_password

  # Adds `destroy` (soft, sets deleted_at), `really_destroy!` (hard delete), `restore`/`restore!`,
  # the default_scope that hides deactivated accounts everywhere, and `.with_deleted`/`.only_deleted`.
  # It also patches the uniqueness validator below to ignore deactivated accounts automatically.
  acts_as_paranoid

  before_validation :assign_uuid, on: :create
  before_validation :normalize_email

  after_commit :sync_to_messaging_api, on: %i[create update], if: :sync_relevant_attributes_changed?
  after_commit :remove_from_messaging_api, on: :destroy

  validates :name, :lastname, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: URI::MailTo::EMAIL_REGEXP
  validates :uuid, presence: true, uniqueness: true
  validate :avatar_within_limits

  def full_name
    [name, lastname].compact.join(" ")
  end

  # Overriding serializable_hash (not as_json) so this also applies when a User is serialized as a
  # nested association (e.g. Post#as_json(include: { comments: { include: :user } })), which Rails
  # builds by calling serializable_hash on the association directly, bypassing as_json overrides.
  def serializable_hash(options = nil)
    options ||= {}
    super(options.merge(except: Array(options[:except]) | [:password_digest]))
      .merge("full_name" => full_name, "avatar_url" => avatar_url)
  end

  private

  def avatar_url
    return nil unless avatar.attached?

    Rails.application.routes.url_helpers.rails_blob_url(avatar, **ActiveStorage::Current.url_options.to_h)
  end

  def avatar_within_limits
    return unless avatar.attached? && avatar.blob

    unless avatar.blob.content_type.in?(AVATAR_ALLOWED_TYPES)
      errors.add(:avatar, "has an unsupported content type")
    end

    if avatar.blob.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "exceeds the #{AVATAR_MAX_SIZE / 1.megabyte}MB size limit")
    end
  end

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def normalize_email
    self.email = email.strip.downcase if email
  end

  def sync_relevant_attributes_changed?
    saved_change_to_name? || saved_change_to_lastname?
  end

  def sync_to_messaging_api
    SyncUserToMessagingApiJob.perform_later(
      SyncUserToMessagingApiJob::UPSERT, uuid, name: name, lastname: lastname, full_name: full_name
    )
  end

  def remove_from_messaging_api
    SyncUserToMessagingApiJob.perform_later(SyncUserToMessagingApiJob::DELETE, uuid)
  end
end
