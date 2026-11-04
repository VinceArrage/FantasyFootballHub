# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_04_000000) do
  create_table "accounts", force: :cascade do |t|
    t.string "sleeper_username", null: false
    t.string "sleeper_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "injury_events", force: :cascade do |t|
    t.integer "player_id", null: false
    t.string "from_status"
    t.string "to_status"
    t.datetime "observed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observed_at"], name: "index_injury_events_on_observed_at"
    t.index ["player_id"], name: "index_injury_events_on_player_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.string "sleeper_id", null: false
    t.string "name", null: false
    t.integer "season", null: false
    t.json "scoring_settings", default: {}, null: false
    t.json "roster_positions", default: [], null: false
    t.json "settings", default: {}, null: false
    t.integer "total_rosters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "history_synced_through", default: 0, null: false
    t.index ["sleeper_id"], name: "index_leagues_on_sleeper_id", unique: true
  end

  create_table "matchups", force: :cascade do |t|
    t.integer "league_id", null: false
    t.integer "team_id", null: false
    t.integer "week", null: false
    t.integer "matchup_id"
    t.decimal "points", precision: 8, scale: 2, default: "0.0", null: false
    t.json "starters", default: [], null: false
    t.json "players_points", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "team_id", "week"], name: "index_matchups_on_league_id_and_team_id_and_week", unique: true
    t.index ["league_id"], name: "index_matchups_on_league_id"
    t.index ["team_id"], name: "index_matchups_on_team_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "sleeper_id", null: false
    t.string "full_name", null: false
    t.string "position"
    t.string "nfl_team"
    t.json "fantasy_positions", default: [], null: false
    t.string "status"
    t.string "injury_status"
    t.string "injury_body_part"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sleeper_id"], name: "index_players_on_sleeper_id", unique: true
  end

  create_table "projections", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "season", null: false
    t.integer "week", null: false
    t.json "stats", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "season", "week"], name: "index_projections_on_player_id_and_season_and_week", unique: true
    t.index ["player_id"], name: "index_projections_on_player_id"
    t.index ["season", "week"], name: "index_projections_on_season_and_week"
  end

  create_table "roster_spots", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "player_id", null: false
    t.boolean "starter", default: false, null: false
    t.integer "slot_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reserve", default: false, null: false
    t.index ["player_id"], name: "index_roster_spots_on_player_id"
    t.index ["team_id", "player_id"], name: "index_roster_spots_on_team_id_and_player_id", unique: true
    t.index ["team_id"], name: "index_roster_spots_on_team_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "finished_at"], name: "index_sync_runs_on_kind_and_finished_at"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "league_id", null: false
    t.integer "sleeper_roster_id", null: false
    t.string "owner_sleeper_id"
    t.string "owner_name"
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "ties", default: 0, null: false
    t.decimal "points_for", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "points_against", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "waiver_budget_used", default: 0, null: false
    t.boolean "mine", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "sleeper_roster_id"], name: "index_teams_on_league_id_and_sleeper_roster_id", unique: true
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  create_table "trade_ideas", force: :cascade do |t|
    t.integer "league_id", null: false
    t.integer "opponent_team_id", null: false
    t.json "give_ids", default: [], null: false
    t.json "get_ids", default: [], null: false
    t.decimal "my_gain", precision: 8, scale: 2, null: false
    t.decimal "their_delta", precision: 8, scale: 2, null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_trade_ideas_on_league_id"
    t.index ["opponent_team_id"], name: "index_trade_ideas_on_opponent_team_id"
  end

  create_table "trades", force: :cascade do |t|
    t.integer "league_id", null: false
    t.string "sleeper_transaction_id", null: false
    t.integer "week", null: false
    t.datetime "executed_at"
    t.json "roster_ids", default: [], null: false
    t.json "adds", default: {}, null: false
    t.json "draft_picks", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_trades_on_league_id"
    t.index ["sleeper_transaction_id"], name: "index_trades_on_sleeper_transaction_id", unique: true
  end

  add_foreign_key "injury_events", "players"
  add_foreign_key "matchups", "leagues"
  add_foreign_key "matchups", "teams"
  add_foreign_key "projections", "players"
  add_foreign_key "roster_spots", "players"
  add_foreign_key "roster_spots", "teams"
  add_foreign_key "teams", "leagues"
  add_foreign_key "trade_ideas", "leagues"
  add_foreign_key "trade_ideas", "teams", column: "opponent_team_id"
  add_foreign_key "trades", "leagues"
end
