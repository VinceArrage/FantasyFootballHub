module Trades
  # Who has won a trade so far: actual fantasy points each side's incoming players
  # scored for them in the weeks after the deal.
  class Scorecard
    Side = Data.define(:team, :received, :picks, :points_since)

    def initialize(trade)
      @trade = trade
    end

    def call
      @call ||= @trade.received.map do |team, players|
        Side.new(team:, received: players, picks: @trade.picks_for(team), points_since: points_since(team, players))
      end
    end

    def winner
      ranked = call.sort_by { -_1.points_since }
      return if ranked.size < 2 || ranked[0].points_since == ranked[1].points_since

      ranked.first.team
    end

    private

    def points_since(team, players)
      ids = players.map(&:sleeper_id)
      team.matchups.where(week: (@trade.week + 1)..).sum do |m|
        ids.sum { |id| m.players_points[id].to_f }
      end.round(2)
    end
  end
end
