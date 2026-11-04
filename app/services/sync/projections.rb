module Sync
  class Projections
    # Sleeper's own pre-computed totals and draft data; everything else is a stat
    # line we score ourselves (including DEF pts_allow).
    IGNORED_KEYS = %w[pts_std pts_ppr pts_half_ppr].freeze
    IGNORED_PREFIXES = %w[adp_ pos_adp_].freeze

    def initialize(source: Sleeper::ProjectionsSource.new)
      @source = source
    end

    def call(season:, from_week:, to_week:)
      player_ids = Player.pluck(:sleeper_id, :id).to_h
      raise Sleeper::Error, "No players synced yet; projections need the player list first" if player_ids.empty?

      (from_week..to_week).each do |week|
        rows = @source.week(season, week).filter_map do |sleeper_id, stats|
          id = player_ids[sleeper_id] or next
          { player_id: id, season:, week:, stats: clean(stats) }
        end
        raise Sleeper::Error, "Projections for week #{week} matched no players" if rows.empty?

        Projection.where(season:, week:).where.not(player_id: rows.map { _1[:player_id] }).delete_all
        Projection.upsert_all(rows, unique_by: %i[player_id season week])
      end
      Projection.where(season:, week: ...from_week).delete_all
    end

    private

    def clean(stats) = stats.reject { |k, _| IGNORED_KEYS.include?(k) || k.start_with?(*IGNORED_PREFIXES) }
  end
end
