class AddReserveToRosterSpots < ActiveRecord::Migration[8.1]
  def change
    add_column :roster_spots, :reserve, :boolean, null: false, default: false
  end
end
