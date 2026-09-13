require "rails_helper"

RSpec.describe RevokedToken, type: :model do
  it "is valid with a user, a jti and an expiry" do
    revoked_token = RevokedToken.new(user: users(:one), jti: SecureRandom.uuid, expires_at: 1.day.from_now)

    expect(revoked_token).to be_valid
  end

  it "prevents the same jti from being revoked twice" do
    jti = SecureRandom.uuid
    RevokedToken.create!(user: users(:one), jti: jti, expires_at: 1.day.from_now)

    duplicate = RevokedToken.new(user: users(:one), jti: jti, expires_at: 1.day.from_now)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:jti]).to include("has already been taken")
  end

  describe ".expired" do
    it "only includes tokens past their expiry" do
      expired = RevokedToken.create!(user: users(:one), jti: SecureRandom.uuid, expires_at: 1.day.ago)
      RevokedToken.create!(user: users(:one), jti: SecureRandom.uuid, expires_at: 1.day.from_now)

      expect(RevokedToken.expired).to eq([expired])
    end
  end
end
