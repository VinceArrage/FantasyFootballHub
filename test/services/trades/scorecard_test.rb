require "test_helper"

class Trades::ScorecardTest < ActiveSupport::TestCase
  setup { sync_fixture_leagues(week: 9) }

  test "only complete trades are stored" do
    all = LEAGUE_IDS.flat_map { |id| (1..9).flat_map { |w| sleeper_json("transactions_#{id}_#{w}.json") } }
    expected = all.select { _1["type"] == "trade" && _1["status"] == "complete" }.map { _1["transaction_id"] }.uniq
    assert expected.any?
    assert_equal expected.sort, Trade.pluck(:sleeper_transaction_id).sort
  end

  test "points_since sums matchups after the trade week" do
    trade = Trade.first
    side = Trades::Scorecard.new(trade).call.first
    ids = side.received.map(&:sleeper_id)
    expected = side.team.matchups.where(week: (trade.week + 1)..).sum { |m| ids.sum { m.players_points[_1].to_f } }
    assert_in_delta expected, side.points_since, 0.01
  end

  test "draft picks are listed but not valued" do
    trade = Trade.first
    team = trade.teams.first
    trade.update!(draft_picks: [ { "season" => "2027", "round" => 1, "owner_id" => team.sleeper_roster_id } ])
    side = Trades::Scorecard.new(trade).call.find { _1.team == team }
    assert_equal 1, side.picks.size
  end

  test "past weeks are backfilled once" do
    assert_equal 8, League.find_by(sleeper_id: GATINEAU).history_synced_through
  end
end
