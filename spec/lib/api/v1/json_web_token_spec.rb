require "rails_helper"

RSpec.describe Api::V1::JsonWebToken do
  describe ".encode" do
    it "encodes a token carrying the user's id and uuid" do
      token = described_class.encode(users(:one))
      payload = JWT.decode(token, nil, false).first

      expect(payload["sub"]).to eq(users(:one).id)
      expect(payload["uuid"]).to eq(users(:one).uuid)
    end

    it "encodes a service token when no user is given" do
      token = described_class.encode
      payload = JWT.decode(token, nil, false).first

      expect(payload).to eq("service" => "social-api")
    end
  end

  describe ".decode" do
    it "returns the payload for a valid token" do
      token = described_class.encode(users(:one))

      expect(described_class.decode(token)["sub"]).to eq(users(:one).id)
    end

    it "returns nil for a malformed token" do
      expect(described_class.decode("not-a-token")).to be_nil
    end

    it "returns nil for a revoked token" do
      token = JWT.encode(
        { sub: users(:one).id, jti: revoked_tokens(:active).jti, exp: 24.hours.from_now.to_i },
        described_class.send(:secret),
        described_class::ALGORITHM
      )

      expect(described_class.decode(token)).to be_nil
    end
  end
end
