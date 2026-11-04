class CreateCoreModels < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :sleeper_username, null: false
      t.string :sleeper_user_id, null: false
      t.timestamps
    end

    create_table :leagues do |t|
      t.string :sleeper_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.integer :season, null: false
      t.json :scoring_settings, null: false, default: {}
      t.json :roster_positions, null: false, default: []
      t.json :settings, null: false, default: {}
      t.integer :total_rosters
      t.timestamps
    end

    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.integer :sleeper_roster_id, null: false
      t.string :owner_sleeper_id
      t.string :owner_name
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.integer :ties, null: false, default: 0
      t.decimal :points_for, precision: 8, scale: 2, null: false, default: 0
      t.decimal :points_against, precision: 8, scale: 2, null: false, default: 0
      t.integer :waiver_budget_used, null: false, default: 0
      t.boolean :mine, null: false, default: false
      t.timestamps
      t.index %i[league_id sleeper_roster_id], unique: true
    end

    create_table :players do |t|
      t.string :sleeper_id, null: false, index: { unique: true }
      t.string :full_name, null: false
      t.string :position
      t.string :nfl_team
      t.json :fantasy_positions, null: false, default: []
      t.string :status
      t.string :injury_status
      t.string :injury_body_part
      t.timestamps
    end

    create_table :roster_spots do |t|
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.boolean :starter, null: false, default: false
      t.integer :slot_index
      t.timestamps
      t.index %i[team_id player_id], unique: true
    end

    create_table :matchups do |t|
      t.references :league, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :week, null: false
      t.integer :matchup_id
      t.decimal :points, precision: 8, scale: 2, null: false, default: 0
      t.json :starters, null: false, default: []
      t.json :players_points, null: false, default: {}
      t.timestamps
      t.index %i[league_id team_id week], unique: true
    end

    create_table :sync_runs do |t|
      t.string :kind, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error
      t.timestamps
      t.index %i[kind finished_at]
    end
  end
end
