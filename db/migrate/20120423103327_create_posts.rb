class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :country
      t.string :facebook_id
      t.integer :kind
      t.text :message
      t.datetime :created_time
      t.references :user
      t.timestamps
    end
    add_index :posts, :user_id
    add_index :posts, :facebook_id, :unique => true
    add_index :posts, :country
  end
end
