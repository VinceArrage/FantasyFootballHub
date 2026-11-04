class SyncJob < ApplicationJob
  queue_as :default

  def perform(kind)
    SyncRun.track(kind) { public_send("sync_#{kind}") }
  end

  def sync_players
    Sync::Players.new.call
  end

  def sync_leagues
    Sync::Leagues.new.call(season: Nfl::Calendar.season, week: Nfl::Calendar.week)
  end

  def sync_projections
  end
end
