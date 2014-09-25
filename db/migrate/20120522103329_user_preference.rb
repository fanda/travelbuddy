class UserPreference < ActiveRecord::Migration
  def change
    add_column :users, :preference, :integer, :default => 1
  end
end
