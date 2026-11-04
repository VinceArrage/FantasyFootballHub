class CreateProjections < ActiveRecord::Migration[8.1]
  def change
    create_table :projections do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.integer :week, null: false
      t.json :stats, null: false, default: {}
      t.timestamps
      t.index %i[player_id season week], unique: true
      t.index %i[season week]
    end
  end
end
