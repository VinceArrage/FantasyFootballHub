module Recommendations
  # Free agents ranked by how much they raise my best rest-of-season lineup,
  # nudged up by Sleeper's trending adds.
  class WaiverRanker
    PREFILTER_PER_POSITION = 40
    TRENDING_WEIGHT = 0.1
    DROP_OPTIONS = 3

    def initialize(league, values:, trending: [])
      @league = league
      @values = values
      @trending_rank = trending.each_with_index.to_h { |t, i| [ t["player_id"], i + 1 ] }
    end

    def call(limit: 10)
      my_team = @league.my_team or return []
      roster = my_team.players.to_a
      base = @values.lineup_total(roster)
      drops = drop_candidates(my_team.players.merge(RosterSpot.where(reserve: false)).to_a)

      free_agents.filter_map do |fa|
        gain = (@values.lineup_total(roster + [ fa ]) - base).round(2)
        rank = @trending_rank[fa.sleeper_id]
        next if gain <= 0 && rank.nil?

        { player: fa, gain:, drop: drops.first&.dig(:player), drops:, trending_rank: rank, faab_left: faab_left(my_team),
          score: gain + (rank ? (51 - rank) * TRENDING_WEIGHT : 0) }
      end.sort_by { -_1[:score] }.first(limit)
    end

    private

    def free_agents
      rostered = RosterSpot.joins(:team).where(teams: { league_id: @league.id }).select(:player_id)
      positions = Lineup::Optimizer.eligible_positions(@league.starter_slots)
      Player.where(id: @values.player_ids, position: positions).where.not(id: rostered).to_a
            .reject(&:out?)
            .group_by(&:position)
            .flat_map { |_, players| players.max_by(PREFILTER_PER_POSITION) { @values.ros(_1) } }
    end

    # The lowest rest-of-season values among players who don't make my best
    # lineup, cheapest first. Players in an IR slot don't use a roster spot, so
    # they're never a drop.
    def drop_candidates(roster)
      starting = @values.lineup(roster).lineup.filter_map { |_, c| c&.dig(:player)&.id }
      roster.reject { starting.include?(_1.id) }
            .map { { player: _1, ros: @values.ros(_1) } }
            .min_by(DROP_OPTIONS) { _1[:ros] }
    end

    def faab_left(team)
      return unless @league.faab?

      @league.settings["waiver_budget"].to_i - team.waiver_budget_used
    end
  end
end
