class SyncJob < ApplicationJob
  queue_as :default

  # Trade search is CPU-heavy and shares the web process, so roster changes only
  # trigger it every few hours; new projections always do.
  TRADE_IDEAS_MIN_AGE = 6.hours

  def perform(kind)
    ok = SyncRun.track(kind) { public_send("sync_#{kind}") }
    recompute_trade_ideas(force: kind == "projections") if ok && %w[leagues projections].include?(kind)
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

  private

  def recompute_trade_ideas(force:)
    League.where(season: Nfl::Calendar.season).find_each do |league|
      newest = league.trade_ideas.maximum(:created_at)
      next unless force || newest.nil? || newest < TRADE_IDEAS_MIN_AGE.ago

      ComputeTradeIdeasJob.perform_later(league.id)
    end
  end
end
