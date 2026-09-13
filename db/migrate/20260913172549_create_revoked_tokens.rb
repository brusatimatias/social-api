class CreateRevokedTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :revoked_tokens do |t|
      t.string :jti, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :revoked_tokens, :jti, unique: true
    add_index :revoked_tokens, :expires_at
  end
end
