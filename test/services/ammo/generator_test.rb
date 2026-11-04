require "test_helper"

class Ammo::GeneratorTest < ActiveSupport::TestCase
  setup do
    sync_fixture_leagues(week: 9)
    @league = League.find_by(sleeper_id: GATINEAU)
    mine = @league.matchups.find_by(week: 9, team: @league.my_team)
    @opp = mine.opponent
  end

  def lines(seed: 1) = Ammo::Generator.new(@league, week: 9, rng: Random.new(seed)).call

  test "injured starter line names the player" do
    starter = Player.find_by(sleeper_id: @opp.starters.first)
    starter.update!(injury_status: "Out")
    line = lines.find { _1[:kind] == :injured_starter && _1[:text].include?(starter.full_name) }
    assert line, "expected a line about #{starter.full_name}"
    assert_includes line[:text], @opp.team.display_name
  end

  test "no injured or bye lines when the opponent lineup is healthy and projections are missing" do
    Player.where(sleeper_id: @opp.starters).update_all(injury_status: nil)
    kinds = lines.map { _1[:kind] }
    refute_includes kinds, :injured_starter
    refute_includes kinds, :bye_starter
  end

  test "worst week uses a real past score" do
    worst = @opp.team.matchups.where(week: ...9).where("points > 0").order(:points).first
    line = lines.find { _1[:kind] == :worst_week }
    assert_includes line[:text], "week #{worst.week}"
  end

  test "deterministic with a seeded rng" do
    assert_equal lines(seed: 42), lines(seed: 42)
  end

  test "no opponent means no lines" do
    @league.matchups.where(week: 9).update_all(matchup_id: nil)
    assert_empty lines
  end

  test "a starter whose projection row is empty gets a bye line (S4)" do
    starter = Player.find_by(sleeper_id: @opp.starters.first)
    other = Player.find_by(sleeper_id: @opp.starters.second)
    Projection.create!(player: starter, season: 2026, week: 9, stats: {})
    Projection.create!(player: other, season: 2026, week: 9, stats: { "gp" => 1.0, "rec" => 3 })
    texts = lines.select { _1[:kind] == :bye_starter }.map { _1[:text] }
    assert texts.any? { _1.include?(starter.full_name) }
    refute texts.any? { _1.include?(other.full_name) }
  end
end
