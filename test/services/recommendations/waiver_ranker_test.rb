require "test_helper"

class Recommendations::WaiverRankerTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues
    sync_fixture_projections
    @league = League.find_by(sleeper_id: GATINEAU)
    @values = Valuation::PlayerValues.new(@league, week: 9)
  end

  def rank(league = @league, trending: []) = Recommendations::WaiverRanker.new(league, values: Valuation::PlayerValues.new(league, week: 9), trending:).call

  test "never suggests rostered or Out players" do
    rostered = RosterSpot.joins(:team).where(teams: { league_id: @league.id }).pluck(:player_id)
    picks = rank
    assert picks.any?
    picks.each do |w|
      refute_includes rostered, w[:player].id
      refute w[:player].out?
    end
  end

  test "gain is positive unless trending, and sorted by score" do
    picks = rank
    picks.each { |w| assert w[:gain].positive? || w[:trending_rank] }
    assert_equal picks.map { -_1[:score] }.sort, picks.map { -_1[:score] }
  end

  test "an RB-starved roster ranks an RB first" do
    my = @league.my_team
    my.roster_spots.joins(:player).where(players: { position: "RB" }).delete_all
    assert_equal "RB", rank.first[:player].position
  end

  test "faab_left only for FAAB leagues" do
    assert_kind_of Integer, rank.first[:faab_left]
    assert_nil rank(League.find_by(sleeper_id: VERSATERM)).first&.dig(:faab_left)
  end

  test "no kickers suggested in a league without a K slot" do
    refute rank(League.find_by(sleeper_id: GAME_OF_INCHES)).any? { _1[:player].position == "K" }
  end
end
