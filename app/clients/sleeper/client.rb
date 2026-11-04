require "faraday"
require "faraday/retry"

module Sleeper
  # Read-only wrapper around the public Sleeper API (https://docs.sleeper.com).
  class Client
    BASE_URL = "https://api.sleeper.app/v1".freeze
    RETRY_STATUSES = [ 429, 500, 502, 503, 504 ].freeze

    def initialize(connection: nil, retry_interval: 0.5)
      @connection = connection || self.class.build_connection(BASE_URL, retry_interval:)
    end

    def self.build_connection(base_url, retry_interval: 0.5, timeout: 10)
      Faraday.new(url: base_url, request: { timeout: }) do |f|
        f.request :retry, max: 3, interval: retry_interval, backoff_factor: 2,
                          retry_statuses: RETRY_STATUSES, methods: %i[get],
                          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS +
                                      [ Faraday::ConnectionFailed, Faraday::TooManyRequestsError, Faraday::ServerError ]
        f.response :raise_error
        f.response :json
      end
    end

    def state = get("state/nfl")
    def user(username) = get("user/#{ERB::Util.url_encode(username)}")
    def leagues(user_id, season) = get("user/#{user_id}/leagues/nfl/#{season}")
    def league(id) = get("league/#{id}")
    def users(league_id) = get("league/#{league_id}/users")
    def rosters(league_id) = get("league/#{league_id}/rosters")
    def matchups(league_id, week) = get("league/#{league_id}/matchups/#{week}")
    def transactions(league_id, week) = get("league/#{league_id}/transactions/#{week}")
    def players = get("players/nfl", timeout: 60)

    def trending_adds(lookback_hours: 24, limit: 50)
      get("players/nfl/trending/add", lookback_hours:, limit:)
    end

    private

    def get(path, timeout: nil, **params)
      response = @connection.get(path, params) { |req| req.options.timeout = timeout if timeout }
      response.body
    rescue Faraday::Error => e
      raise Sleeper::Error.new("Sleeper #{path}: #{e.message}", status: e.response&.dig(:status))
    end
  end
end
