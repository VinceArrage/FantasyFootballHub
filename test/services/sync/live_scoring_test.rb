require "test_helper"

class Sync::LiveScoringTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues(week: 9)
    @league = League.find_by(sleeper_id: GATINEAU)
  end

  def bump_scores(week: 9)
    LEAGUE_IDS.each do |id|
      body = sleeper_json("matchups_#{id}_#{week}.json").each { _1["points"] = _1["points"].to_f + _1["roster_id"] }
      stub_sleeper("/league/#{id}/matchups/#{week}", body: body.to_json)
    end
  end

  test "broadcasts scoreboard and standings when points change" do
    bump_scores
    assert_turbo_stream_broadcasts [ @league, :scoreboard ], count: 1 do
      assert_turbo_stream_broadcasts [ @league, :standings ], count: 1 do
        Sync::LiveScoring.new(client: sleeper_client).call(week: 9)
      end
    end
  end

  test "no broadcast when nothing changed" do
    assert_no_turbo_stream_broadcasts [ @league, :scoreboard ] do
      Sync::LiveScoring.new(client: sleeper_client).call(week: 9)
    end
  end

  test "provisional standings count the current leader as a win" do
    bump_scores
    Sync::LiveScoring.new(client: sleeper_client).call(week: 9)
    mine = @league.matchups.find_by(week: 9, team: @league.my_team)
    row = Standings::Live.rows(@league, week: 9).find { _1.team.mine }
    expected = mine.points <=> mine.opponent.points
    assert_equal expected, row.provisional
    assert_equal @league.my_team.wins + (expected == 1 ? 1 : 0), row.wins
  end
end
