require "test_helper"

class Sync::CatchUpTest < ActiveSupport::TestCase
  def sun_10am = Time.find_zone("America/New_York").parse("2026-11-08 10:00")
  def tue_10am = Time.find_zone("America/New_York").parse("2026-11-10 10:00")

  def succeed(kind, at:) = SyncRun.create!(kind:, started_at: at, finished_at: at)
  def catch_up(now, game_day:) = Sync::CatchUp.new(now:, game_day:)

  test "everything due on first boot" do
    assert_equal %w[leagues players projections], catch_up(sun_10am, game_day: true).due_kinds.sort
  end

  test "players due after 3h on a Sunday, not on a Tuesday" do
    succeed("players", at: sun_10am - 3.hours)
    assert_includes catch_up(sun_10am, game_day: true).due_kinds, "players"
    succeed("players", at: tue_10am - 3.hours)
    refute_includes catch_up(tue_10am, game_day: false).due_kinds, "players"
  end

  test "laptop wake after 9h makes leagues due" do
    succeed("leagues", at: tue_10am - 9.hours)
    assert_includes catch_up(tue_10am, game_day: false).due_kinds, "leagues"
  end

  test "running sync is not double-enqueued" do
    SyncRun.create!(kind: "leagues", started_at: tue_10am - 2.minutes)
    refute_includes catch_up(tue_10am, game_day: false).due_kinds, "leagues"
  end

  test "a failed sync stays due" do
    SyncRun.create!(kind: "leagues", started_at: tue_10am - 5.minutes, finished_at: tue_10am - 5.minutes, error: "503")
    assert_includes catch_up(tue_10am, game_day: false).due_kinds, "leagues"
  end
end
