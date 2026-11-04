class CreateInjuryEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :injury_events do |t|
      t.references :player, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status
      t.datetime :observed_at, null: false
      t.timestamps
      t.index :observed_at
    end
  end
end
