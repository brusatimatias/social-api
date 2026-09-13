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

    it "requires a name and a lastname" do
      user = described_class.new(email: "new.user@example.com", password: "password")

      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
      expect(user.errors[:lastname]).to include("can't be blank")
    end

    it "requires a unique uuid" do
      user = described_class.new(
        name: "Another", lastname: "Ada", email: "another.ada@example.com", password: "password",
        uuid: users(:one).uuid
      )

      expect(user).not_to be_valid
      expect(user.errors[:uuid]).to include("has already been taken")
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

  describe "#destroy" do
    it "sets deleted_at instead of destroying the record" do
      user = users(:one)

      expect { user.destroy }.to change(user, :deleted_at).from(nil)
      expect(User.with_deleted.exists?(user.id)).to be true
    end

    it "also soft-deletes the user's own posts" do
      users(:one).destroy

      expect(posts(:one).reload.deleted_at).to be_present
    end

    it "leaves other users' posts untouched" do
      users(:one).destroy

      expect(posts(:two).reload.deleted_at).to be_nil
    end
  end

  describe "default_scope" do
    it "excludes deactivated users from normal queries" do
      users(:one).destroy

      expect(User.all).not_to include(users(:one))
      expect(User.find_by(id: users(:one).id)).to be_nil
    end

    it "still finds a deactivated user via .with_deleted" do
      users(:one).destroy

      expect(User.with_deleted).to include(users(:one))
    end
  end

  describe "email reuse after deactivation" do
    it "allows a new user to reuse a deactivated user's email" do
      users(:one).destroy

      new_user = User.new(
        name: "New", lastname: "Owner", email: users(:one).email.upcase, password: "password"
      )

      expect(new_user).to be_valid
    end
  end
end
