require "test_helper"

class Sync::PlayersTest < ActiveSupport::TestCase
  test "upserts players including DET defense" do
    stub_players
    Sync::Players.new(client: sleeper_client).call
    det = Player.find_by(sleeper_id: "DET")
    assert_equal "DEF", det.position
    assert_equal "Detroit Lions", det.full_name
  end

  test "returns injury change when status differs" do
    injured_id, raw = sleeper_json("players_trimmed.json").find { |_, p| p["injury_status"] == "Questionable" }
    Player.create!(sleeper_id: injured_id, full_name: raw["full_name"], injury_status: nil)
    stub_players
    changes = Sync::Players.new(client: sleeper_client).call
    change = changes.find { _1[:player].sleeper_id == injured_id }
    assert_nil change[:from]
    assert_equal "Questionable", change[:to]
  end

  test "first sync and repeat sync report no changes" do
    stub_players
    assert_empty Sync::Players.new(client: sleeper_client).call
    assert_empty Sync::Players.new(client: sleeper_client).call
  end
end
