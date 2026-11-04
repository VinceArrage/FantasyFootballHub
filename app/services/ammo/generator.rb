module Ammo
  # Trash talk built from real facts about this week's opponent. A line only
  # appears when its fact is true.
  class Generator
    def self.templates = @templates ||= YAML.load_file(Rails.root.join("config/ammo_templates.yml"))

    def initialize(league, week:, rng: Random.new)
      @league = league
      @week = week
      @rng = rng
    end

    def call
      mine = @league.matchups.find_by(week: @week, team: @league.my_team)
      @opp_matchup = mine&.opponent or return []
      @opponent = @opp_matchup.team

      [ *injured_starters, *bye_starters, worst_week, lost_trade, bottom_standings ].compact
    end

    private

    def line(kind, **vars)
      { kind:, text: format(self.class.templates.fetch(kind.to_s).sample(random: @rng), opponent: @opponent.display_name, **vars) }
    end

    def opponent_starters = @opp_starters ||= Player.where(sleeper_id: @opp_matchup.starters).to_a

    def injured_starters
      opponent_starters.select(&:out?).map { line(:injured_starter, player: _1.full_name, status: _1.injury_status) }
    end

    # Sleeper returns a row for players on bye, just with no stats (or gp 0).
    def bye_starters
      return [] unless Projection.where(season: @league.season, week: @week).exists? # not synced: can't tell

      playing = Projection.where(season: @league.season, week: @week, player: opponent_starters)
                          .select { |p| p.stats.present? && p.stats.fetch("gp", 1).to_f.positive? }.map(&:player_id)
      opponent_starters.reject { playing.include?(_1.id) }.map { line(:bye_starter, player: _1.full_name) }
    end

    def worst_week
      worst = @opponent.matchups.where(week: ...@week).where("points > 0").order(:points).first or return
      line(:worst_week, week: worst.week, points: format("%.1f", worst.points))
    end

    def lost_trade
      @league.trades.each do |trade|
        card = Trades::Scorecard.new(trade)
        next unless card.winner && card.winner != @opponent && card.call.any? { _1.team == @opponent }

        sides = card.call.index_by(&:team)
        margin = sides[card.winner].points_since - sides[@opponent].points_since
        return line(:lost_trade, points: format("%.1f", margin))
      end
      nil
    end

    def bottom_standings
      ranked = @league.teams.standings.to_a
      rank = ranked.index(@opponent) + 1
      return unless rank > ranked.size - 3

      line(:bottom_standings, rank: rank.ordinalize, teams: ranked.size)
    end
  end
end
