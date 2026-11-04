require "test_helper"

class Sync::LeaguesTest < ActiveSupport::TestCase
  setup do
    create_account
    stub_players
    Sync::Players.new(client: sleeper_client).call
  end

  test "syncs three leagues and marks my team" do
    stub_all_leagues
    leagues = Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9)
    assert_equal 3, leagues.size
    leagues.each { |l| assert_equal MY_USER_ID, l.my_team.owner_sleeper_id }
    assert_equal 3, Team.where(mine: true).count
  end

  test "points_for combines fpts and decimal" do
    stub_all_leagues
    Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9)
    team = League.find_by(sleeper_id: GATINEAU).teams.find_by(sleeper_roster_id: 1)
    assert_equal 884.12, team.points_for.to_f
  end

  test "empty starter slot '0' creates no player" do
    stub_all_leagues
    rosters = sleeper_json("rosters_#{GATINEAU}.json")
    rosters.first["starters"][0] = "0"
    stub_sleeper("/league/#{GATINEAU}/rosters", body: rosters.to_json)
    Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9)
    assert_nil Player.find_by(sleeper_id: "0")
    team = League.find_by(sleeper_id: GATINEAU).teams.find_by(sleeper_roster_id: rosters.first["roster_id"])
    assert_equal rosters.first["starters"].count { _1 != "0" }, team.roster_spots.where(starter: true).count
  end

  test "unknown roster player gets stub" do
    stub_all_leagues
    rosters = sleeper_json("rosters_#{GATINEAU}.json")
    rosters.first["players"] << "99999"
    stub_sleeper("/league/#{GATINEAU}/rosters", body: rosters.to_json)
    Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9)
    assert_equal "Unknown (99999)", Player.find_by(sleeper_id: "99999").full_name
  end

  test "Sleeper 503 leaves existing leagues intact" do
    stub_all_leagues
    Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9)
    stub_sleeper("/user/#{MY_USER_ID}/leagues/nfl/2026", body: "", status: 503)
    refute SyncRun.track("leagues") { Sync::Leagues.new(client: sleeper_client).call(season: 2026, week: 9) }
    assert_equal 3, League.count
    assert SyncRun.last.error.present?
  end
end
