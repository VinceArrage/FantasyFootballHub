class LiveScoringJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    return unless Account.current && Nfl::Calendar.live?(now)

    SyncRun.track("live") { Sync::LiveScoring.new.call(week: Nfl::Calendar.week) }
  end
end
