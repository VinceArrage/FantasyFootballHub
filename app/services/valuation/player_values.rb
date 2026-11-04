module Valuation
  # Projected value of every projected player in one league, under that league's
  # scoring: this week, rest of season (through the championship week), and value
  # over replacement.
  class PlayerValues
    attr_reader :league, :week

    def initialize(league, week:)
      @league = league
      @week = week
      @calculator = Scoring::Calculator.new(league.scoring_settings)
      load_points
    end

    def ros(player) = @ros[player.id]
    def this_week(player) = @this_week[player.id]
    def vor(player) = (ros(player) - replacement(player.position)).round(2)
    def player_ids = @ros.keys

    def candidates(players, by: :ros) = players.reject(&:out?).map { |p| { player: p, points: public_send(by, p) } }

    def lineup(players, by: :ros) = Lineup::Optimizer.new(league.starter_slots).call(candidates(players, by:))
    def lineup_total(players) = lineup(players).total

    def replacement(position)
      @replacement ||= {}
      @replacement[position] ||= begin
        starters = league.total_rosters.to_i * league.starter_slots.count(position)
        ranked = @positions.select { |_, pos| pos == position }.keys.map { @ros[_1] }.sort.reverse
        ranked[starters] || 0.0
      end
    end

    private

    def load_points
      @ros = Hash.new(0.0)
      @this_week = Hash.new(0.0)
      Projection.where(season: league.season, week: week..league.playoff_end_week)
                .pluck(:player_id, :week, :stats).each do |player_id, w, stats|
        pts = @calculator.points(stats)
        @ros[player_id] += pts
        @this_week[player_id] = pts if w == week
      end
      @positions = Player.where(id: @ros.keys).pluck(:id, :position).to_h
    end
  end
end
