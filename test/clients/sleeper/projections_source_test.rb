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

  test "a sync that matches no players fails instead of looking fresh (S8)" do
    sync_fixture_leagues
    stub_sleeper("/projections/nfl/2026/9", body: [ { player_id: "nobody", stats: {} } ].to_json, base: PROJECTIONS_BASE)
    refute SyncRun.track("projections") do
      Sync::Projections.new(source: Sleeper::ProjectionsSource.new(retry_interval: 0)).call(season: 2026, from_week: 9, to_week: 9)
    end
  end

  test "projections before the current week are pruned" do
    sync_fixture_leagues
    Projection.create!(player: Player.first, season: 2026, week: 3, stats: { "rec" => 1 })
    sync_fixture_projections
    refute Projection.where(week: 3).exists?
  end
end
