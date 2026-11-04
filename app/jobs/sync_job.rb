class SyncJob < ApplicationJob
  queue_as :default

  def perform(kind)
    SyncRun.track(kind) { public_send("sync_#{kind}") }
  end

  def sync_players
    Injuries::Recorder.call(Sync::Players.new.call)
  end

  def sync_leagues
    Sync::Leagues.new.call(season: Nfl::Calendar.season, week: Nfl::Calendar.week)
  end

  def sync_projections
    last_week = League.where(season: Nfl::Calendar.season).map(&:playoff_end_week).max || 17
    Sync::Projections.new.call(season: Nfl::Calendar.season, from_week: Nfl::Calendar.week, to_week: last_week)
  end
end
