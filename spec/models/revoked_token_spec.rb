require "rails_helper"

RSpec.describe RevokedToken, type: :model do
  it "is valid with a user, a jti and an expiry" do
    expect(revoked_tokens(:active)).to be_valid
  end

  it "requires a jti" do
    revoked_token = RevokedToken.new(user: users(:one), expires_at: 1.day.from_now)

    expect(revoked_token).not_to be_valid
    expect(revoked_token.errors[:jti]).to include("can't be blank")
  end

  it "requires an expiry" do
    revoked_token = RevokedToken.new(user: users(:one), jti: SecureRandom.uuid)

    expect(revoked_token).not_to be_valid
    expect(revoked_token.errors[:expires_at]).to include("can't be blank")
  end

  it "prevents the same jti from being revoked twice" do
    duplicate = RevokedToken.new(
      user: users(:one), jti: revoked_tokens(:active).jti, expires_at: 1.day.from_now
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:jti]).to include("has already been taken")
  end

  describe ".expired" do
    it "only includes tokens past their expiry" do
      expect(RevokedToken.expired).to contain_exactly(revoked_tokens(:expired))
    end
  end
end
