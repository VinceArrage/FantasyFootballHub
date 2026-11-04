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
