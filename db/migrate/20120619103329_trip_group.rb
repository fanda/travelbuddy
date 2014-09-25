class TripGroup < ActiveRecord::Migration
  def change
    create_table :trips do |t|
      t.string :name
      t.text   :about
      t.timestamps
    end

    create_table :trips_users do |t|
      t.integer  :user_id
      t.integer  :trip_id
      t.integer  :notification
    end
    add_index :trips_users, :user_id
    add_index :trips_users, :trip_id

    add_column :travels, :trip_id, :integer
    add_index  :travels, :trip_id

  end
end
