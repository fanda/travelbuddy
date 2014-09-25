class CreateTravels < ActiveRecord::Migration
  def change
    create_table :travels do |t|
      t.string :country
      t.date :begins
      t.date :ends
      t.references :user
      t.timestamps
    end
    add_index :travels, :user_id
  end
end
