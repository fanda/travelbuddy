class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid
      t.string :uname
      t.string :uemail
      t.string :token

      t.timestamps
    end
    add_index :services, :user_id
    add_index :services, :provider
  end
end
