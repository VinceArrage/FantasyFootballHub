require "test_helper"

class Sleeper::ProjectionsSourceTest < ActiveSupport::TestCase
  setup { @source = Sleeper::ProjectionsSource.new(retry_interval: 0) }

  test "parses player stats keyed by sleeper id" do
    stub_projections(9..9)
    week = @source.week(2026, 9)
    assert week.values.first.is_a?(Hash)
    assert week.keys.all?(String)
  end

  test "shape drift raises Sleeper::Error" do
    stub_sleeper("/projections/nfl/2026/9", body: { error: "x" }.to_json, base: PROJECTIONS_BASE)
    assert_raises(Sleeper::Error) { @source.week(2026, 9) }
  end

  test "sync stores weeks 9 through 17" do
    sync_fixture_leagues
    sync_fixture_projections
    assert_equal (9..17).to_a, Projection.distinct.pluck(:week).sort
  end
end
