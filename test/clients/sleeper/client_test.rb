require "test_helper"

class Sleeper::ClientTest < ActiveSupport::TestCase
  setup { @client = Sleeper::Client.new(retry_interval: 0) }

  test "user returns user_id" do
    stub_sleeper("/user/kingarrage", "user_kingarrage.json")
    assert_equal "985266740114305024", @client.user("kingarrage")["user_id"]
  end

  test "leagues for season" do
    stub_sleeper("/user/985266740114305024/leagues/nfl/2026", "leagues_2026.json")
    assert_equal [ "Game of Inches", "Gatineau boys 2026", "Versaterm Fantasy League" ],
                 @client.leagues("985266740114305024", 2026).map { _1["name"] }.sort
  end

  test "trending adds passes query params" do
    stub_request(:get, "https://api.sleeper.app/v1/players/nfl/trending/add?lookback_hours=24&limit=50")
      .to_return(body: sleeper_fixture("trending_add.json"), headers: { "Content-Type" => "application/json" })
    assert_equal 50, @client.trending_adds.size
  end

  test "429 retries then raises Sleeper::Error with status" do
    stub_request(:get, %r{/state/nfl}).to_return(status: 429)
    err = assert_raises(Sleeper::Error) { @client.state }
    assert_equal 429, err.status
    assert_requested :get, %r{/state/nfl}, times: 4
  end

  test "timeout raises Sleeper::Error" do
    stub_request(:get, %r{/state/nfl}).to_timeout
    assert_raises(Sleeper::Error) { @client.state }
  end
end
