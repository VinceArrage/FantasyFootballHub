module Recommendations
  # Searches 1-for-1, 2-for-1 and 1-for-2 swaps with every opponent. A trade is
  # kept when it improves my best rest-of-season lineup and doesn't hurt theirs,
  # so they'd plausibly accept.
  class TradeFinder
    TOP_PER_SIDE = 12
    MAX_PER_OPPONENT = 2

    def initialize(league, values:, tolerance: 0.0)
      @league = league
      @values = values
      @tolerance = tolerance
    end

    def call(limit: 5)
      me = @league.my_team or return []
      mine = me.players.to_a
      my_base = @values.lineup_total(mine)

      ideas = @league.teams.where.not(id: me.id).flat_map do |opp|
        theirs = opp.players.to_a
        their_base = @values.lineup_total(theirs)
        swaps(top(mine), top(theirs)).filter_map do |give, get|
          my_gain = (@values.lineup_total(after(mine, give, get)) - my_base).round(2)
          next unless my_gain.positive?

          their_delta = (@values.lineup_total(after(theirs, get, give)) - their_base).round(2)
          next if their_delta < -@tolerance

          { opponent_team: opp, give:, get:, my_gain:, their_delta: }
        end.sort_by { -_1[:my_gain] }.first(MAX_PER_OPPONENT)
      end

      ideas.sort_by { -_1[:my_gain] }.first(limit).map { |idea| attributes(idea) }
    end

    private

    def top(players) = players.reject(&:out?).max_by(TOP_PER_SIDE) { @values.ros(_1) }

    def swaps(mine, theirs)
      ones = ->(list) { list.map { [ _1 ] } }
      pairs = ->(list) { list.combination(2).to_a }
      ones.(mine).product(ones.(theirs)) + pairs.(mine).product(ones.(theirs)) + ones.(mine).product(pairs.(theirs))
    end

    # Roster after the swap. A side receiving more players than it sends cuts its
    # lowest-value player who isn't part of the deal.
    def after(roster, outgoing, incoming)
      result = roster - outgoing + incoming
      (incoming.size - outgoing.size).times do
        cut = (result - incoming).min_by { @values.ros(_1) }
        result -= [ cut ] if cut
      end
      result
    end

    def attributes(idea)
      {
        league: @league, opponent_team: idea[:opponent_team], give_ids: idea[:give].map(&:id),
        get_ids: idea[:get].map(&:id), my_gain: idea[:my_gain], their_delta: idea[:their_delta],
        reason: reason(idea)
      }
    end

    def reason(idea)
      get = idea[:get].map(&:position).tally.keys.join("/")
      give = idea[:give].map(&:position).tally.keys.join("/")
      them = idea[:their_delta].positive? ? "and helps them too (+#{idea[:their_delta]})" : "without hurting their lineup"
      "You turn #{give} depth into a #{get} upgrade (+#{idea[:my_gain]} pts rest of season) #{them}."
    end
  end
end
