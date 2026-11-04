module Scoring
  # Fantasy points for a stat line under one league's scoring settings.
  # Sleeper uses the same keys for stats and scoring settings (rec, pass_td, ...).
  class Calculator
    def initialize(scoring_settings)
      @settings = (scoring_settings || {}).transform_values(&:to_f)
    end

    def points(stats)
      return 0.0 if stats.blank?

      stats.sum do |key, value|
        next 0.0 if key.start_with?("pts_")

        value.to_f * @settings.fetch(key, 0.0)
      end.round(2)
    end
  end
end
