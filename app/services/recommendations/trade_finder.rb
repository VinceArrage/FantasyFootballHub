module Recommendations
  # Proposes trades that fix what my team is missing. My needs are the position
  # groups where my starters rank in the league's bottom third (see
  # Valuation::TeamNeeds). Searches 1-for-1, 2-for-1 and 1-for-2 swaps with every
  # opponent and keeps a trade only when it raises one of those groups, improves
  # my best rest-of-season lineup overall, every player I receive would start,
  # and it doesn't hurt the other lineup, so they'd plausibly accept. Kickers and
  # defenses are left out. Trades that also fill one of *their* needs rank
  # higher: those are the ones they're most likely to say yes to.
  # With no needs (every group ranks mid-pack or better), any upgrade qualifies.
  class TradeFinder
    TOP_PER_SIDE = 12
    MAX_PER_OPPONENT = 2
    MUTUAL_BONUS = 1.25
    MIN_GROUP_GAIN = 0.5

    def initialize(league, values:, tolerance: 0.0)
      @league = league
      @values = values
      @tolerance = tolerance
      @needs = Valuation::TeamNeeds.new(league, values:)
    end

    def call(limit: 6)
      me = @league.my_team or return []
      mine = me.players.to_a
      my_needs = @needs.report(me).needs
      my_before = evaluate(mine)

      ideas = @league.teams.where.not(id: me.id).includes(:players).flat_map do |opp|
        theirs = opp.players.to_a
        their_needs = @needs.report(opp).needs
        their_before = evaluate(theirs)

        swaps(top(mine), top(theirs)).filter_map do |give, get|
          my_after = evaluate(after(mine, give, get))
          my_gain = (my_after[:total] - my_before[:total]).round(2)
          next unless my_gain.positive?
          next unless (get - my_after[:starters]).empty? # no filler I'd just cut or bench

          fills = improved(my_before, my_after, my_needs.presence || @needs.groups)
          next if fills.empty?

          their_after = evaluate(after(theirs, get, give))
          their_delta = (their_after[:total] - their_before[:total]).round(2)
          next if their_delta < -@tolerance

          their_fills = improved(their_before, their_after, their_needs)
          score = my_gain * (their_fills.any? ? MUTUAL_BONUS : 1.0)
          { opponent_team: opp, give:, get:, my_gain:, their_delta:, fills:, their_fills:, score:,
            my_before:, my_after:, needs_driven: my_needs.any? }
        end.sort_by { -_1[:score] }.uniq { _1[:get].map(&:id).sort }.first(MAX_PER_OPPONENT)
      end

      ideas.sort_by { -_1[:score] }.first(limit).map { |idea| attributes(me, idea) }
    end

    private

    def evaluate(players)
      lineup = @values.lineup(players)
      { total: lineup.total, groups: @needs.points_from(lineup), starters: lineup.lineup.filter_map { _2&.dig(:player) } }
    end

    # Groups (from the candidates) whose lineup points go up meaningfully.
    def improved(before, after, groups)
      groups.select { after[:groups][_1] - before[:groups][_1] >= MIN_GROUP_GAIN }
            .sort_by { before[:groups][_1] - after[:groups][_1] }
    end

    UNTRADED = %w[K DEF].freeze

    def top(players)
      players.reject { _1.out? || UNTRADED.include?(_1.position) }.max_by(TOP_PER_SIDE) { @values.ros(_1) }
    end

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

    def attributes(me, idea)
      {
        league: @league, opponent_team: idea[:opponent_team], give_ids: idea[:give].map(&:id),
        get_ids: idea[:get].map(&:id), my_gain: idea[:my_gain], their_delta: idea[:their_delta],
        my_need: idea[:needs_driven] ? idea[:fills].join(",") : nil,
        their_need: idea[:their_fills].join(",").presence,
        reason: reason(me, idea)
      }
    end

    def reason(me, idea)
      moves = @needs.groups.filter_map do |group|
        before = @needs.rank(me, group, idea[:my_before][:groups][group])
        now = @needs.rank(me, group, idea[:my_after][:groups][group])
        [ group, "#{group} #{before.ordinalize} → #{now.ordinalize}" ] if now < before
      end.to_h
      group = idea[:fills].first
      head = idea[:needs_driven] ? "Fills your #{idea[:fills].to_sentence} need" : "Upgrades your #{group}"
      ranks = moves.any? ? " (#{moves.values.join(', ')} of #{@league.teams.size})" : ""
      head += ranks
      them =
        if idea[:their_fills].any?
          "They're thin at #{idea[:their_fills].to_sentence}, so it fills a hole for them too"
        elsif idea[:their_delta].positive?
          "Their lineup gets better too (+#{idea[:their_delta]})"
        else
          "Their lineup doesn't get worse"
        end
      "#{head}: +#{idea[:my_gain]} pts rest of season. #{them}."
    end
  end
end
