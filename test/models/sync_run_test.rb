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
end
