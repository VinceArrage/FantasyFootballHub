class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :league, null: false, foreign_key: true
      t.string :sleeper_transaction_id, null: false, index: { unique: true }
      t.integer :week, null: false
      t.datetime :executed_at
      t.json :roster_ids, null: false, default: []
      t.json :adds, null: false, default: {}
      t.json :draft_picks, null: false, default: []
      t.timestamps
    end

    create_table :trade_ideas do |t|
      t.references :league, null: false, foreign_key: true
      t.references :opponent_team, null: false, foreign_key: { to_table: :teams }
      t.json :give_ids, null: false, default: []
      t.json :get_ids, null: false, default: []
      t.decimal :my_gain, precision: 8, scale: 2, null: false
      t.decimal :their_delta, precision: 8, scale: 2, null: false
      t.string :reason
      t.timestamps
    end

    add_column :leagues, :history_synced_through, :integer, null: false, default: 0
  end
end
