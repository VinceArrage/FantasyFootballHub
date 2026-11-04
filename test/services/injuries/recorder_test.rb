require "test_helper"

class Injuries::RecorderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    sync_fixture_leagues
    @league = League.find_by(sleeper_id: GATINEAU)
    @my_starter = @league.my_team.starters.first
  end

  test "records Q to healthy as a cleared event" do
    event = Injuries::Recorder.call([ { player: @my_starter, from: "Questionable", to: nil } ]).first
    assert event.cleared?
  end

  test "broadcasts fresh flags for leagues where the player is rostered" do
    perform_enqueued_jobs do
      assert_turbo_stream_broadcasts [ @league, :injuries ] do
        Injuries::Recorder.call([ { player: @my_starter, from: nil, to: "Out" } ])
      end
    end
  end

  test "no broadcast for an empty change list" do
    perform_enqueued_jobs do
      assert_no_turbo_stream_broadcasts [ @league, :injuries ] do
        Injuries::Recorder.call([])
      end
    end
  end

  test "injury to a player not on my rosters is not pushed to the feed (B2)" do
    stranger = Player.create!(sleeper_id: "stranger", full_name: "Not Mine", position: "WR")
    perform_enqueued_jobs do
      assert_no_turbo_stream_broadcasts :injuries do
        Injuries::Recorder.call([ { player: stranger, from: nil, to: "Out" } ])
      end
      assert_turbo_stream_broadcasts :injuries do
        Injuries::Recorder.call([ { player: @my_starter, from: nil, to: "Out" } ])
      end
    end
  end
end
