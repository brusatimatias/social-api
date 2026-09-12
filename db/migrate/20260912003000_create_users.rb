class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users do |t|
      t.string :name, null: false
      t.string :lastname, null: false
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, :uuid, unique: true
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
