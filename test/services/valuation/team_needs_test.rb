require "test_helper"

class Valuation::TeamNeedsTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues
    sync_fixture_projections
  end

  def needs(league) = Valuation::TeamNeeds.new(league, values: Valuation::PlayerValues.new(league, week: 9))

  test "ranks every group against the whole league" do
    league = League.find_by(sleeper_id: GATINEAU)
    report = needs(league).report(league.my_team)
    assert_equal %w[QB RB WR TE FLEX], report.rows.map(&:group)
    report.rows.each do |row|
      assert_includes 1..league.teams.size, row.rank
      assert_equal league.teams.size, row.teams
    end
  end

  test "bottom third is a need and top third a strength" do
    n = needs(League.find_by(sleeper_id: GATINEAU))
    assert_equal :strength, n.status(4)
    assert_equal :ok, n.status(5)
    assert_equal :ok, n.status(8)
    assert_equal :need, n.status(9)
  end

  test "the league's best group ranks first and its worst ranks last" do
    league = League.find_by(sleeper_id: VERSATERM)
    n = needs(league)
    reports = league.teams.map { n.report(_1) }
    n.groups.each do |group|
      ranks = reports.map { _1.row(group).rank }
      assert_includes ranks, 1
      best = reports.max_by { _1.row(group).points }
      assert_equal 1, best.row(group).rank
    end
  end

  test "FLEX is filled by the flex slots' positions" do
    n = needs(League.find_by(sleeper_id: GATINEAU))
    assert_equal %w[RB WR TE], n.positions_for("FLEX")
    assert_equal %w[QB], n.positions_for("QB")
  end

  test "surplus is healthy bench players above replacement, never starters, kickers or defenses" do
    LEAGUE_IDS.each do |id|
      league = League.find_by(sleeper_id: id)
      report = needs(league).report(league.my_team)
      starters = report.rows.flat_map(&:starters)
      assert starters.any?
      report.surplus.each do |p|
        assert_not p.out?
        assert_not_includes starters, p
        assert_not_includes %w[K DEF], p.position
      end
    end
  end
end
