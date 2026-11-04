module Standings
  # Season record plus a provisional result for the week in progress: whoever is
  # ahead right now gets the win.
  module Live
    Row = Data.define(:team, :wins, :losses, :ties, :points_for, :provisional)

    module_function

    def rows(league, week:)
      matchups = league.matchups.where(week:).to_a
      by_team = matchups.index_by(&:team_id)
      in_progress = matchups.any? { _1.points.positive? }

      league.teams.map do |team|
        w, l, t = team.wins, team.losses, team.ties
        provisional = nil
        mine = by_team[team.id]
        opp = mine && matchups.find { _1.matchup_id == mine.matchup_id && _1.team_id != team.id }
        if in_progress && opp
          provisional = mine.points <=> opp.points
          case provisional
          when 1 then w += 1
          when -1 then l += 1
          else t += 1
          end
        end
        Row.new(team:, wins: w, losses: l, ties: t, points_for: team.points_for + (mine&.points || 0), provisional:)
      end.sort_by { |r| [ -r.wins, -r.points_for ] }
    end
  end
end
