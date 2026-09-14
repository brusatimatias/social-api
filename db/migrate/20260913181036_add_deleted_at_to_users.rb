class AddDeletedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at

    # Replace the plain unique index with a partial one so a deactivated account's email
    # can be reused by a new registration, while still enforcing uniqueness among active users.
    remove_index :users, name: "index_users_on_lower_email"
    add_index :users, "lower(email)", unique: true, where: "deleted_at IS NULL",
      name: "index_users_on_lower_email"
  end
end
