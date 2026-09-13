class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
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

  before_validation :assign_uuid, on: :create
  before_validation :normalize_email

  validates :name, :lastname, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: URI::MailTo::EMAIL_REGEXP
  validates :uuid, presence: true, uniqueness: true

  def full_name
    [name, lastname].compact.join(" ")
  end

  def as_json(options = {})
    super(options.merge(except: Array(options[:except]) | [:password_digest])).merge("full_name" => full_name)
  end

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def normalize_email
    self.email = email.strip.downcase if email
  end
end
