module Nfl
  # Season/week facts from Sleeper's /state/nfl, plus game-day rules in Eastern time.
  module Calendar
    ZONE = "America/New_York".freeze
    SATURDAY_GAMES_FROM_WEEK = 15

    module_function

    def state(client: Sleeper::Client.new)
      Rails.cache.fetch("nfl/state", expires_in: 1.hour) { client.state }
    rescue Sleeper::Error
      # Offline: fall back to what we last synced.
      { "season" => League.maximum(:season) || Date.current.year, "week" => Matchup.maximum(:week) || 1 }
    end

    def season = state["season"].to_i
    def week = [ state["week"].to_i, 1 ].max
    def display_week = state["display_week"] || week

    def game_day?(time, week: self.week)
      t = time.in_time_zone(ZONE)
      t.thursday? || t.sunday? || t.monday? || (t.saturday? && week >= SATURDAY_GAMES_FROM_WEEK)
    end

    def live?(time, week: self.week)
      t = time.in_time_zone(ZONE)
      day = t.strftime("%A").downcase
      return false if day == "saturday" && week < SATURDAY_GAMES_FROM_WEEK

      start_hour, end_hour = game_windows[day]
      start_hour.present? && t.hour >= start_hour && t.hour < end_hour
    end

    def game_windows
      @game_windows ||= YAML.load_file(Rails.root.join("config/game_windows.yml"))
    end
  end
end
