class AddPopularityToTravels < ActiveRecord::Migration
  def change
    add_column :travels, :popularity, :integer
  end
end
