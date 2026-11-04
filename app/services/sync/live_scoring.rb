module Sync
  # Refreshes this week's matchup scores and pushes the scoreboard and live
  # standings to open pages, only for leagues where a score actually moved.
  class LiveScoring
    def initialize(client: Sleeper::Client.new)
      @client = client
    end

    def call(week:)
      League.where(season: Nfl::Calendar.season).select { |league| refresh(league, week) }.each do |league|
        broadcast(league, week)
      end
    end

    private

    def refresh(league, week)
      teams = league.teams.index_by(&:sleeper_roster_id)
      changed = false
      @client.matchups(league.sleeper_id, week).each do |m|
        team = teams[m["roster_id"]] or next
        matchup = league.matchups.find_or_initialize_by(team:, week:)
        matchup.assign_attributes(matchup_id: m["matchup_id"], points: m["points"].to_f,
                                  starters: m["starters"] || [], players_points: m["players_points"] || {})
        changed ||= matchup.points_changed? || matchup.new_record?
        matchup.save!
      end
      changed
    end

    def broadcast(league, week)
      Turbo::StreamsChannel.broadcast_replace_to(
        [ league, :scoreboard ], target: ActionView::RecordIdentifier.dom_id(league, :scoreboard),
        partial: "leagues/scoreboard", locals: { league:, week: }
      )
      Turbo::StreamsChannel.broadcast_replace_to(
        [ league, :standings ], target: ActionView::RecordIdentifier.dom_id(league, :standings),
        partial: "leagues/standings", locals: { league:, week: }
      )
    end
  end
end
