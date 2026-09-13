require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with the required attributes" do
      user = described_class.new(
        name: "Katherine",
        lastname: "Johnson",
        email: "new.user@example.com",
        password: "password"
      )

      expect(user).to be_valid
      expect(user.uuid).to match(/\A[0-9a-f-]{36}\z/)
      expect(user.full_name).to eq("Katherine Johnson")
    end

    it "normalizes email before validation" do
      user = described_class.new(
        name: "Alan",
        lastname: "Turing",
        email: "  ALAN@EXAMPLE.COM ",
        password: "password"
      )

      expect(user).to be_valid
      expect(user.email).to eq("alan@example.com")
    end

    it "requires a unique email" do
      user = described_class.new(
        name: "Another",
        lastname: "Ada",
        email: " ADA@EXAMPLE.COM ",
        password: "password"
      )

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end
  end

  it "authenticates with the password" do
    expect(users(:one).authenticate("password")).to eq(users(:one))
    expect(users(:one).authenticate("wrong password")).to be_falsey
  end

  describe "serialization" do
    it "excludes the password digest and includes the full name" do
      json = users(:one).as_json

      expect(json).not_to have_key("password_digest")
      expect(json["full_name"]).to eq(users(:one).full_name)
    end

    it "excludes the password digest when serialized as a nested association" do
      json = comments(:one).as_json(include: :user)

      expect(json["user"]).not_to have_key("password_digest")
      expect(json["user"]["full_name"]).to eq(users(:two).full_name)
    end
  end
end
