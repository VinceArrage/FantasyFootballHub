module Nfl
  # Season/week facts from Sleeper's /state/nfl, plus game-day rules in Eastern time.
  module Calendar
    ZONE = "America/New_York".freeze
    SATURDAY_GAMES_FROM_WEEK = 15
    CACHE_KEY = "nfl/state".freeze

    module_function

    def state(client: Sleeper::Client.new)
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) { client.state }
    rescue Sleeper::Error
      # Offline: fall back to what we last synced, and don't retry on every page load.
      fallback = { "season" => League.maximum(:season) || Date.current.year, "week" => Matchup.maximum(:week) || 1 }
      Rails.cache.write(CACHE_KEY, fallback, expires_in: 5.minutes)
      fallback
    end

    def season = state["season"].to_i
    def week = [ state["week"].to_i, 1 ].max
    def display_week = state["display_week"] || week

    def game_day?(time, week: self.week)
      t = time.in_time_zone(ZONE)
      t.thursday? || t.sunday? || t.monday? || (t.saturday? && week >= SATURDAY_GAMES_FROM_WEEK) ||
        special_day?(t)
    end

    def live?(time, week: self.week)
      t = time.in_time_zone(ZONE)
      day = t.strftime("%A").downcase
      window = game_windows[day] unless day == "saturday" && week < SATURDAY_GAMES_FROM_WEEK
      window = game_windows["special"] if special_day?(t)
      window.present? && t.hour >= window[0] && t.hour < window[1]
    end

    # Thanksgiving, Black Friday, Christmas and other one-off game days.
    def special_day?(time) = Array(game_windows["special_dates"]).map(&:to_s).include?(time.in_time_zone(ZONE).to_date.iso8601)

    def game_windows
      @game_windows ||= YAML.load_file(Rails.root.join("config/game_windows.yml"), permitted_classes: [ Date ])
    end
  end
end
