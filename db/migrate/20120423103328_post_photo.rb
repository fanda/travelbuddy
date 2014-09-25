class PostPhoto < ActiveRecord::Migration
  def change
    add_column :posts, :photo, :string
  end
end
