module Valuation
  # Where each team is thin or deep. Every team's best rest-of-season lineup is
  # split into position groups (QB, RB, WR, TE, and the FLEX slots together) and
  # each group is ranked against the rest of the league. Bottom third is a need,
  # top third a strength. Healthy bench players worth more than replacement level
  # are surplus: the depth a team can trade away without weakening its lineup.
  class TeamNeeds
    GROUPS = %w[QB RB WR TE FLEX].freeze
    Row = Data.define(:group, :points, :rank, :teams, :median, :status, :starters) do
      def need? = status == :need
      def strength? = status == :strength
      def gap = (points - median).round(1)
    end
    Report = Data.define(:team, :rows, :surplus) do
      def needs = rows.select(&:need?).map(&:group)
      def strengths = rows.select(&:strength?).map(&:group)
      def row(group) = rows.find { _1.group == group }
    end

    def initialize(league, values:)
      @league = league
      @values = values
      @slots = league.starter_slots
      @groups = GROUPS.select { |g| @slots.any? { group_of(_1) == g } }
      @points = league.teams.includes(:players).to_h { |t| [ t.id, group_points(t.players.to_a) ] }
    end

    attr_reader :groups

    # Lineup points per position group for a set of players.
    def group_points(players)
      points_from(@values.lineup(players))
    end

    def points_from(lineup)
      totals = @groups.to_h { [ _1, 0.0 ] }
      lineup.lineup.each do |slot, pick|
        group = group_of(slot)
        totals[group] += pick[:points] if pick && totals.key?(group)
      end
      totals.transform_values { _1.round(2) }
    end

    # Rank (1 = best) a team would have in a group with these points, against
    # every other team as they stand now.
    def rank(team, group, points)
      1 + @points.count { |id, g| id != team.id && g[group] > points }
    end

    def status(rank)
      third = (teams_count / 3.0).floor
      return :need if rank > teams_count - third
      return :strength if rank <= third
      :ok
    end

    # Positions that can fill a group's slots.
    def positions_for(group)
      return [ group ] unless group == "FLEX"
      Lineup::Optimizer.eligible_positions(@slots.select { group_of(_1) == "FLEX" })
    end

    def report(team)
      players = team.players.to_a
      lineup = @values.lineup(players)
      mine = points_from(lineup)
      starters = lineup.lineup.filter_map { |slot, pick| [ group_of(slot), pick[:player] ] if pick }
      started = starters.map(&:last)

      rows = @groups.map do |group|
        r = rank(team, group, mine[group])
        Row.new(group:, points: mine[group], rank: r, teams: teams_count, median: median(group), status: status(r),
                starters: starters.select { _1.first == group }.map(&:last))
      end
      surplus = (players - started).reject { |p| p.out? || %w[K DEF].include?(p.position) }
                                   .select { |p| @values.vor(p).positive? }
                                   .sort_by { -@values.ros(_1) }
      Report.new(team:, rows:, surplus:)
    end

    private

    def teams_count = @points.size

    def median(group)
      sorted = @points.values.map { _1[group] }.sort
      mid = sorted.size / 2
      (sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0).round(1)
    end

    def group_of(slot)
      Lineup::Optimizer::ELIGIBLE.fetch(slot, []).size > 1 ? "FLEX" : slot
    end
  end
end
