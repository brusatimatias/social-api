require "rails_helper"

RSpec.describe SocialMessagingApiClient do
  def stub_connection
    stubs = Faraday::Adapter::Test::Stubs.new
    connection = Faraday.new do |f|
      f.request :json
      f.adapter :test, stubs
    end
    allow(described_class).to receive(:connection).and_return(connection)
    stubs
  end

  describe ".upsert_user" do
    it "PUTs the user to the internal upsert endpoint" do
      stubs = stub_connection
      stubs.put("/api/v1/internal/users/uuid-1") do |env|
        expect(JSON.parse(env.body)).to eq(
          "name" => "Ada", "lastname" => "Lovelace", "fullName" => "Ada Lovelace"
        )
        [200, {}, ""]
      end

      described_class.upsert_user(
        uuid: "uuid-1", name: "Ada", lastname: "Lovelace", full_name: "Ada Lovelace"
      )

      stubs.verify_stubbed_calls
    end

    it "raises when the upsert fails" do
      stubs = stub_connection
      stubs.put("/api/v1/internal/users/uuid-1") { [500, {}, ""] }

      expect do
        described_class.upsert_user(
          uuid: "uuid-1", name: "Ada", lastname: "Lovelace", full_name: "Ada Lovelace"
        )
      end.to raise_error(described_class::Error)
    end
  end

  describe ".delete_user" do
    it "DELETEs the user from the internal endpoint" do
      stubs = stub_connection
      stubs.delete("/api/v1/internal/users/uuid-1") { [204, {}, ""] }

      expect { described_class.delete_user(uuid: "uuid-1") }.not_to raise_error
      stubs.verify_stubbed_calls
    end

    it "tolerates a 404 (already deleted)" do
      stubs = stub_connection
      stubs.delete("/api/v1/internal/users/uuid-1") { [404, {}, ""] }

      expect { described_class.delete_user(uuid: "uuid-1") }.not_to raise_error
    end

    it "raises for other failures" do
      stubs = stub_connection
      stubs.delete("/api/v1/internal/users/uuid-1") { [500, {}, ""] }

      expect { described_class.delete_user(uuid: "uuid-1") }.to raise_error(described_class::Error)
    end
  end
end
