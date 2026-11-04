require "test_helper"

class Scoring::CalculatorTest < ActiveSupport::TestCase
  STATS = { "rec" => 5, "rec_yd" => 60, "rec_td" => 1 }.freeze

  test "PPR vs standard on the same stat line" do
    assert_equal 17.0, Scoring::Calculator.new("rec" => 1.0, "rec_yd" => 0.1, "rec_td" => 6).points(STATS)
    assert_equal 12.0, Scoring::Calculator.new("rec" => 0.0, "rec_yd" => 0.1, "rec_td" => 6).points(STATS)
  end

  test "ignores pre-computed pts_ keys" do
    assert_equal 0.0, Scoring::Calculator.new("pts_ppr" => 1.0).points("pts_ppr" => 20.0)
  end

  test "nil stats is zero (bye week)" do
    assert_equal 0.0, Scoring::Calculator.new("rec" => 1.0).points(nil)
  end

  test "DEF points-allowed buckets still score (S11)" do
    assert_equal 7.0, Scoring::Calculator.new("pts_allow_0" => 10.0, "pts_allow_1_6" => 7.0).points("pts_allow_1_6" => 1)
  end
end
