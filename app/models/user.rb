class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
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
