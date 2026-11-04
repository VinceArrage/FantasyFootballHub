module Sync
  class Projections
    IGNORED_PREFIXES = %w[pts_ adp_ pos_adp_].freeze

    def initialize(source: Sleeper::ProjectionsSource.new)
      @source = source
    end

    def call(season:, from_week:, to_week:)
      player_ids = Player.pluck(:sleeper_id, :id).to_h
      (from_week..to_week).each do |week|
        rows = @source.week(season, week).filter_map do |sleeper_id, stats|
          id = player_ids[sleeper_id] or next
          { player_id: id, season:, week:, stats: stats.reject { |k, _| k.start_with?(*IGNORED_PREFIXES) } }
        end
        Projection.upsert_all(rows, unique_by: %i[player_id season week]) if rows.any?
      end
    end
  end
end
