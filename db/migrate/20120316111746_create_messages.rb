class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :user
      t.text :text
      t.boolean :active, :default => true
      t.timestamps
    end
    add_index :messages, :user_id
  end
end
