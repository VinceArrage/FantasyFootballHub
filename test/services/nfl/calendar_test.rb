require "test_helper"

class Nfl::CalendarTest < ActiveSupport::TestCase
  def et(str) = Time.find_zone("America/New_York").parse(str)

  test "game days are Thu, Sun, Mon in Eastern time" do
    assert Nfl::Calendar.game_day?(et("2026-11-08 10:00"), week: 9) # Sunday
    assert Nfl::Calendar.game_day?(et("2026-11-05 21:00"), week: 9) # Thursday
    refute Nfl::Calendar.game_day?(et("2026-11-10 10:00"), week: 9) # Tuesday
  end

  test "Saturday is a game day only from week 15" do
    refute Nfl::Calendar.game_day?(et("2026-11-07 14:00"), week: 9)
    assert Nfl::Calendar.game_day?(et("2026-12-19 14:00"), week: 15)
  end

  test "week and season come from sleeper state" do
    stub_sleeper("/state/nfl", "state.json")
    Rails.cache.clear
    assert_equal 2026, Nfl::Calendar.season
    assert_equal 9, Nfl::Calendar.week
  end

  test "live on Sunday 1pm ET, not Tuesday" do
    assert Nfl::Calendar.live?(et("2026-11-08 13:00"), week: 9)
    refute Nfl::Calendar.live?(et("2026-11-10 13:00"), week: 9)
    refute Nfl::Calendar.live?(et("2026-11-08 08:00"), week: 9)
  end

  test "Saturday live only from week 15" do
    refute Nfl::Calendar.live?(et("2026-11-07 16:00"), week: 9)
    assert Nfl::Calendar.live?(et("2026-12-19 16:00"), week: 15)
  end

  test "Thanksgiving, Black Friday and Christmas are live (S5)" do
    assert Nfl::Calendar.live?(et("2026-11-26 13:00"), week: 12)
    assert Nfl::Calendar.live?(et("2026-11-27 15:00"), week: 12)
    assert Nfl::Calendar.live?(et("2026-12-25 16:00"), week: 16)
    assert Nfl::Calendar.game_day?(et("2026-11-27 15:00"), week: 12)
  end
end
