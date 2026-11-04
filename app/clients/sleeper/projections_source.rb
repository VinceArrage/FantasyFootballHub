module Sleeper
  # Sleeper's projections endpoint is undocumented, so it lives behind this one
  # class and fails loudly (Sleeper::Error) if its shape ever drifts.
  class ProjectionsSource
    BASE_URL = "https://api.sleeper.com".freeze
    POSITIONS = %w[QB RB WR TE K DEF].freeze

    def initialize(connection: nil, retry_interval: 0.5)
      @connection = connection || Client.build_connection(BASE_URL, retry_interval:, timeout: 30)
    end

    # => { "sleeper_id" => { "rec" => 4.2, ... } }
    def week(season, week)
      query = POSITIONS.map { "position[]=#{_1}" }.join("&")
      body = @connection.get("projections/nfl/#{season}/#{week}?season_type=regular&#{query}").body
      unless body.is_a?(Array) && body.all? { |row| row.is_a?(Hash) && row.key?("player_id") && row.key?("stats") }
        raise Sleeper::Error, "Unexpected projections shape for #{season} week #{week}"
      end

      body.to_h { |row| [ row["player_id"], row["stats"] || {} ] }
    rescue Faraday::Error => e
      raise Sleeper::Error.new("Sleeper projections: #{e.message}", status: e.response&.dig(:status))
    end
  end
end
