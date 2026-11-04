require "test_helper"

class Injuries::FlagsTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues
    @team = League.find_by(sleeper_id: GATINEAU).my_team
    @team.players.update_all(injury_status: nil)
  end

  test "healthy full roster has no flags" do
    assert_empty Injuries::Flags.for(@team)
  end

  test "injured starter flagged red before bench" do
    @team.bench.first.update!(injury_status: "Questionable")
    @team.starters.first.update!(injury_status: "Out")
    flags = Injuries::Flags.for(@team)
    assert_equal [ :red, :yellow ], flags.map { _1[:severity] }
    assert flags.first[:starter]
  end

  test "empty starter slot is a red flag" do
    @team.roster_spots.where(starter: true).first.update!(starter: false)
    flag = Injuries::Flags.for(@team).first
    assert_nil flag[:player]
    assert_equal :red, flag[:severity]
  end
end
