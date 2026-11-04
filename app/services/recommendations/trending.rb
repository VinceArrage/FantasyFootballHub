module Recommendations
  module Trending
    # Sleeper's most-added players over the last day. A failure just means no boost.
    def self.adds(client: Sleeper::Client.new)
      Rails.cache.fetch("sleeper/trending_adds", expires_in: 1.hour) { client.trending_adds }
    rescue Sleeper::Error
      []
    end
  end
end
