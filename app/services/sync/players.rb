module Sync
  # Pulls Sleeper's full player file (~5 MB) and upserts fantasy-relevant players.
  # Returns the injury status changes for players we already knew about.
  class Players
    POSITIONS = %w[QB RB WR TE K DEF].freeze

    def initialize(client: Sleeper::Client.new)
      @client = client
    end

    def call
      rows = @client.players.values.filter_map { |raw| row_for(raw) }
      before = Player.pluck(:sleeper_id, :injury_status).to_h
      Player.upsert_all(rows, unique_by: :sleeper_id) if rows.any?

      changed = rows.select { |r| before.key?(r[:sleeper_id]) && before[r[:sleeper_id]] != r[:injury_status] }
      players = Player.where(sleeper_id: changed.map { _1[:sleeper_id] }).index_by(&:sleeper_id)
      changed.map { |r| { player: players[r[:sleeper_id]], from: before[r[:sleeper_id]], to: r[:injury_status] } }
    end

    private

    def row_for(raw)
      return unless POSITIONS.include?(raw["position"])

      {
        sleeper_id: raw["player_id"],
        full_name: raw["full_name"].presence || [ raw["first_name"], raw["last_name"] ].compact.join(" "),
        position: raw["position"],
        nfl_team: raw["team"],
        fantasy_positions: raw["fantasy_positions"] || [],
        status: raw["status"],
        injury_status: raw["injury_status"],
        injury_body_part: raw["injury_body_part"]
      }
    end
  end
end
