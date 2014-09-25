class CreateFiles < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.string :name
      t.attachment :file
      t.references :trip
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :attachments
  end
end
