module Sync
  # Syncs every league of the account for a season: league settings, teams and
  # records, rosters, and one week of matchups.
  class Leagues
    def initialize(client: Sleeper::Client.new)
      @client = client
    end

    def call(season:, week:)
      account = Account.current
      return [] unless account

      @client.leagues(account.sleeper_user_id, season).map do |raw|
        sync_league(raw, account:, season:, week:)
      end
    end

    private

    def sync_league(raw, account:, season:, week:)
      league = League.find_or_initialize_by(sleeper_id: raw["league_id"])
      league.update!(name: raw["name"], season:, scoring_settings: raw["scoring_settings"] || {},
                     roster_positions: raw["roster_positions"] || [], settings: raw["settings"] || {},
                     total_rosters: raw["total_rosters"])

      owners = @client.users(league.sleeper_id).to_h do |u|
        [ u["user_id"], u.dig("metadata", "team_name").presence || u["display_name"] ]
      end
      teams = @client.rosters(league.sleeper_id).map { |r| sync_team(league, r, owners, account) }
      teams_by_roster = teams.index_by(&:sleeper_roster_id)
      sync_history(league, teams_by_roster, week)
      sync_matchups(league, teams_by_roster, week)
      sync_trades(league, week)
      league
    end

    # Past weeks never change, so they're fetched once: matchups (for the trade
    # scorecard's points) and trades.
    def sync_history(league, teams_by_roster, week)
      ((league.history_synced_through + 1)...week).each do |past|
        sync_matchups(league, teams_by_roster, past)
        sync_trades(league, past)
      end
      league.update!(history_synced_through: week - 1) if league.history_synced_through < week - 1
    end

    def sync_trades(league, week)
      @client.transactions(league.sleeper_id, week).each do |t|
        next unless t["type"] == "trade" && t["status"] == "complete"

        trade = league.trades.find_or_initialize_by(sleeper_transaction_id: t["transaction_id"])
        trade.update!(week: t["leg"] || week, executed_at: Time.zone.at(t["status_updated"].to_i / 1000),
                      roster_ids: t["roster_ids"] || [], adds: t["adds"] || {}, draft_picks: t["draft_picks"] || [])
      end
    end

    def sync_team(league, raw, owners, account)
      s = raw["settings"] || {}
      team = league.teams.find_or_initialize_by(sleeper_roster_id: raw["roster_id"])
      team.update!(
        owner_sleeper_id: raw["owner_id"], owner_name: owners[raw["owner_id"]],
        wins: s["wins"].to_i, losses: s["losses"].to_i, ties: s["ties"].to_i,
        points_for: s["fpts"].to_i + s["fpts_decimal"].to_i / 100.0,
        points_against: s["fpts_against"].to_i + s["fpts_against_decimal"].to_i / 100.0,
        waiver_budget_used: s["waiver_budget_used"].to_i,
        mine: raw["owner_id"] == account.sleeper_user_id
      )
      rebuild_roster(team, raw)
      team
    end

    def rebuild_roster(team, raw)
      starters = real_ids(raw["starters"])
      all_ids = (starters + real_ids(raw["players"]) + real_ids(raw["reserve"])).uniq
      players = ensure_players(all_ids)
      Team.transaction do
        team.roster_spots.delete_all
        rows = all_ids.map do |id|
          slot = starters.index(id)
          { team_id: team.id, player_id: players[id].id, starter: !slot.nil?, slot_index: slot }
        end
        RosterSpot.insert_all(rows) if rows.any?
      end
    end

    def sync_matchups(league, teams_by_roster, week)
      @client.matchups(league.sleeper_id, week).each do |m|
        team = teams_by_roster[m["roster_id"]] or next
        matchup = league.matchups.find_or_initialize_by(team:, week:)
        matchup.update!(matchup_id: m["matchup_id"], points: m["points"].to_f,
                        starters: m["starters"] || [], players_points: m["players_points"] || {})
      end
    end

    # Sleeper uses "0" for an empty starter slot.
    def real_ids(ids) = Array(ids).reject { |id| id.blank? || id == "0" }

    def ensure_players(ids)
      known = Player.where(sleeper_id: ids).index_by(&:sleeper_id)
      (ids - known.keys).each do |id|
        known[id] = Player.create!(sleeper_id: id, full_name: "Unknown (#{id})")
      end
      known
    end
  end
end
