class CreateCheckins < ActiveRecord::Migration
  def change
    create_table :checkins do |t|
      t.string :city
      t.string :country
      t.string :facebook_checkin_id
      t.text :message
      t.datetime :created_time
      t.references :user
      t.timestamps
    end
    add_index :checkins, :user_id
    add_index :checkins, :facebook_checkin_id, :unique => true
    add_index :checkins, :country
  end
end
