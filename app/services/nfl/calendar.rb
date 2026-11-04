module Nfl
  # Season/week facts from Sleeper's /state/nfl, plus game-day rules in Eastern time.
  module Calendar
    ZONE = "America/New_York".freeze
    SATURDAY_GAMES_FROM_WEEK = 15

    module_function

    def state(client: Sleeper::Client.new)
      Rails.cache.fetch("nfl/state", expires_in: 1.hour) { client.state }
    end

    def season = state["season"].to_i
    def week = [ state["week"].to_i, 1 ].max
    def display_week = state["display_week"] || week

    def game_day?(time, week: self.week)
      t = time.in_time_zone(ZONE)
      t.thursday? || t.sunday? || t.monday? || (t.saturday? && week >= SATURDAY_GAMES_FROM_WEEK)
    end
  end
end
