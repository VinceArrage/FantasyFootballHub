require "test_helper"

class Recommendations::TradeFinderTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues
    sync_fixture_projections
  end

  def find(league, **opts) = Recommendations::TradeFinder.new(league, values: Valuation::PlayerValues.new(league, week: 9), **opts).call

  test "every idea helps me and does not hurt them" do
    ideas = find(League.find_by(sleeper_id: GATINEAU), tolerance: 0.0)
    assert ideas.any?, "real rosters should produce at least one idea"
    ideas.each do |idea|
      assert idea[:my_gain].positive?
      assert idea[:their_delta] >= 0
      assert idea[:reason].present?
    end
  end

  test "every idea raises a group I need, and says which" do
    league = League.find_by(sleeper_id: GATINEAU)
    values = Valuation::PlayerValues.new(league, week: 9)
    my_needs = Valuation::TeamNeeds.new(league, values:).report(league.my_team).needs
    assert my_needs.any?, "fixture roster should have at least one need"
    ideas = find(league)
    assert ideas.any?
    ideas.each do |idea|
      assert idea[:my_need].present?
      assert_empty idea[:my_need].split(",") - my_needs
      assert_match(/Fills your/, idea[:reason])
    end
  end

  test "every player I receive would start for me, and kickers and defenses are never traded" do
    league = League.find_by(sleeper_id: VERSATERM)
    values = Valuation::PlayerValues.new(league, week: 9)
    mine = league.my_team.players.to_a
    find(league).each do |idea|
      players = Player.find(idea[:give_ids] + idea[:get_ids])
      assert_empty players.map(&:position) & %w[K DEF]
      after = mine - Player.find(idea[:give_ids]) + Player.find(idea[:get_ids])
      started = values.lineup(after).lineup.filter_map { _2&.dig(:player) }
      assert_empty Player.find(idea[:get_ids]) - started
    end
  end

  test "suggests at most one offer per target player per opponent" do
    LEAGUE_IDS.each do |id|
      keys = find(League.find_by(sleeper_id: id)).map { [ _1[:opponent_team].id, _1[:get_ids].sort ] }
      assert_equal keys.uniq.size, keys.size
    end
  end

  test "never offers or asks for an Out player" do
    out_ids = Player.where(injury_status: Player::OUT_STATUSES).ids
    LEAGUE_IDS.each do |id|
      find(League.find_by(sleeper_id: id)).each { |idea| assert_empty (idea[:give_ids] + idea[:get_ids]) & out_ids }
    end
  end

  test "a bigger tolerance never yields fewer ideas" do
    league = League.find_by(sleeper_id: VERSATERM)
    assert find(league, tolerance: 50.0).size >= find(league).size
  end

  test "the job saves ideas and broadcasts them" do
    league = League.find_by(sleeper_id: GAME_OF_INCHES)
    assert_turbo_stream_broadcasts [ league, :trade_ideas ] do
      ComputeTradeIdeasJob.perform_now(league.id)
    end
    assert_equal find(league).size, league.trade_ideas.count
  end
end
