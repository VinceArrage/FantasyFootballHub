require "test_helper"

class Valuation::PlayerValuesTest < ActiveSupport::TestCase
  setup do
    create_account
    stub_players
    Sync::Players.new(client: sleeper_client).call
    @league = League.create!(sleeper_id: "x", name: "Test", season: 2026, total_rosters: 2,
                             roster_positions: %w[QB RB BN], scoring_settings: { "rush_yd" => 0.1, "pass_td" => 4 },
                             settings: { "playoff_week_start" => 15, "playoff_teams" => 6 })
    @rb = Player.where(position: "RB").first
  end

  test "ros sums weeks through championship week with bye as zero" do
    Projection.create!(player: @rb, season: 2026, week: 9, stats: { "rush_yd" => 100 })
    Projection.create!(player: @rb, season: 2026, week: 17, stats: { "rush_yd" => 50 })
    Projection.create!(player: @rb, season: 2026, week: 18, stats: { "rush_yd" => 999 })
    values = Valuation::PlayerValues.new(@league, week: 9)
    assert_equal 15.0, values.ros(@rb)
    assert_equal 10.0, values.this_week(@rb)
  end

  test "vor replacement is the next QB after league starters" do
    qbs = Player.where(position: "QB").first(4)
    qbs.each_with_index { |qb, i| Projection.create!(player: qb, season: 2026, week: 9, stats: { "pass_td" => 4 - i }) }
    values = Valuation::PlayerValues.new(@league, week: 9)
    # 2 teams x 1 QB slot -> replacement is the 3rd best QB (8 pts)
    assert_equal 8.0, values.replacement("QB")
    assert_equal 8.0, values.vor(qbs.first)
  end

  test "player without projections has ros 0" do
    assert_equal 0.0, Valuation::PlayerValues.new(@league, week: 9).ros(@rb)
  end
end
