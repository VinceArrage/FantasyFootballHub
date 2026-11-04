require "test_helper"

class SmokeTest < ActiveSupport::TestCase
  test "development uses solid adapters" do
    assert_match(/development:\s*\n\s*adapter: solid_cable/, Rails.root.join("config/cable.yml").read)
  end

  test "network is blocked in tests" do
    assert_raises(WebMock::NetConnectNotAllowedError) { Net::HTTP.get(URI("https://api.sleeper.app/v1/state/nfl")) }
  end
end
