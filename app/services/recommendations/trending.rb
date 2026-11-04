module Recommendations
  module Trending
    CACHE_KEY = "sleeper/trending_adds".freeze

    # Sleeper's most-added players over the last day. A failure just means no
    # boost, and is cached briefly so pages don't keep waiting on retries.
    def self.adds(client: Sleeper::Client.new)
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) { client.trending_adds }
    rescue Sleeper::Error
      Rails.cache.write(CACHE_KEY, [], expires_in: 10.minutes)
      []
    end
  end
end
