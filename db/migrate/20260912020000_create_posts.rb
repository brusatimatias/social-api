class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.text :content, null: false
      t.string :visibility, null: false, default: "public"
      t.string :status, null: false, default: "published"
      t.datetime :edited_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
