require "test_helper"

class SyncRunTest < ActiveSupport::TestCase
  test "track records success" do
    assert SyncRun.track("leagues") { :ok }
    assert SyncRun.last_success("leagues")
  end

  test "track records failure and keeps going" do
    refute SyncRun.track("leagues") { raise Sleeper::Error.new("boom", status: 503) }
    assert_nil SyncRun.last_success("leagues")
    assert_match "boom", SyncRun.last.error
  end

  test "non-Sleeper failures are recorded too (S1)" do
    refute SyncRun.track("players") { raise ArgumentError, "bad data" }
    assert_match "ArgumentError: bad data", SyncRun.last.error
    refute SyncRun.last.succeeded?
  end

  test "prune drops runs older than a week" do
    SyncRun.create!(kind: "leagues", started_at: 8.days.ago, finished_at: 8.days.ago)
    SyncRun.create!(kind: "leagues", started_at: 1.day.ago, finished_at: 1.day.ago)
    SyncRun.prune
    assert_equal 1, SyncRun.count
  end
end
