require "test_helper"

class Lineup::OptimizerTest < ActiveSupport::TestCase
  P = Struct.new(:id, :position)

  def candidates(list) = list.each_with_index.map { |(pos, pts), i| { player: P.new(i + 1, pos), points: pts } }

  test "superflex takes second QB over WR3" do
    slots = %w[QB WR WR SUPER_FLEX]
    result = Lineup::Optimizer.new(slots).call(candidates([ [ "QB", 300 ], [ "QB", 250 ], [ "WR", 200 ], [ "WR", 180 ], [ "WR", 170 ] ]))
    assert_equal [ "QB", "WR", "WR", "QB" ], result.lineup.map { |_, c| c[:player].position }
    assert_equal 930.0, result.total
  end

  test "three FLEX take best remaining RB/WR/TE" do
    slots = %w[RB WR TE FLEX FLEX FLEX]
    pool = [ [ "RB", 100 ], [ "RB", 90 ], [ "WR", 95 ], [ "WR", 80 ], [ "TE", 50 ], [ "TE", 40 ], [ "QB", 500 ] ]
    result = Lineup::Optimizer.new(slots).call(candidates(pool))
    assert_equal 100 + 95 + 50 + 90 + 80 + 40, result.total
  end

  test "no kicker slot means kickers never start" do
    result = Lineup::Optimizer.new(%w[QB]).call(candidates([ [ "K", 900 ], [ "QB", 10 ] ]))
    assert_equal 10.0, result.total
  end

  test "short roster leaves slot nil and counts only filled" do
    result = Lineup::Optimizer.new(%w[QB RB RB]).call(candidates([ [ "RB", 20 ] ]))
    assert_equal 2, result.lineup.count { |_, c| c.nil? }
    assert_equal 20.0, result.total
    assert_nil result.lineup.first.last
  end
end
