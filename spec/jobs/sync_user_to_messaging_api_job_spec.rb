require "rails_helper"

RSpec.describe SyncUserToMessagingApiJob do
  describe "#perform" do
    it "upserts the user when the action is upsert" do
      expect(SocialMessagingApiClient).to receive(:upsert_user)
        .with(uuid: "uuid-1", name: "Ada", lastname: "Lovelace", full_name: "Ada Lovelace")

      described_class.perform_now(
        described_class::UPSERT, "uuid-1", name: "Ada", lastname: "Lovelace", full_name: "Ada Lovelace"
      )
    end

    it "deletes the user when the action is delete" do
      expect(SocialMessagingApiClient).to receive(:delete_user).with(uuid: "uuid-1")

      described_class.perform_now(described_class::DELETE, "uuid-1")
    end
  end
end
