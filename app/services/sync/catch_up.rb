module Sync
  # Decides which syncs are stale. Runs every 5 minutes, so a laptop waking from
  # sleep catches up on its own within one tick.
  class CatchUp
    KINDS = %w[players leagues projections].freeze
    IN_FLIGHT_GRACE = 10.minutes

    def initialize(now: Time.current, game_day: Nfl::Calendar.game_day?(now))
      @now = now
      @game_day = game_day
    end

    def due_kinds = KINDS.select { |kind| due?(kind) }

    def interval(kind)
      case kind
      when "leagues" then 1.hour
      when "projections" then 24.hours
      when "players" then @game_day ? 2.hours : 24.hours
      end
    end

    private

    def due?(kind)
      return false if in_flight?(kind)

      last = SyncRun.last_success(kind)
      last.nil? || last.finished_at <= @now - interval(kind)
    end

    def in_flight?(kind)
      SyncRun.where(kind:, finished_at: nil).where(started_at: (@now - IN_FLIGHT_GRACE)..).exists?
    end
  end
end
