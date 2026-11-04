require "test_helper"

class LeagueTest < ActiveSupport::TestCase
  test "playoff_end_week for 6 playoff teams starting wk15" do
    assert_equal 17, League.new(settings: { "playoff_week_start" => 15, "playoff_teams" => 6 }).playoff_end_week
  end

  test "starter_slots drops bench" do
    assert_equal %w[QB RB WR], League.new(roster_positions: %w[QB RB WR BN BN]).starter_slots
  end

  test "faab only for waiver_type 2" do
    assert League.new(settings: { "waiver_type" => 2 }).faab?
    refute League.new(settings: { "waiver_type" => 0 }).faab?
  end
end
