require "rails_helper"

RSpec.describe Api::V1::Response do
  describe ".success" do
    it "builds a successful response envelope" do
      response = described_class.success(data: { id: 1 }, meta: { page: 1 })

      expect(response.as_json).to eq(
        data: { id: 1 },
        errors: [],
        meta: { page: 1 }
      )
    end
  end

  describe ".error" do
    it "builds an error response envelope" do
      response = described_class.error("Invalid request")

      expect(response.as_json).to eq(
        data: nil,
        errors: ["Invalid request"],
        meta: {}
      )
    end
  end
end
