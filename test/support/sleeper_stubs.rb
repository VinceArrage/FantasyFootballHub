module SleeperStubs
  SLEEPER_BASE = "https://api.sleeper.app/v1".freeze
  PROJECTIONS_BASE = "https://api.sleeper.com".freeze
  MY_USER_ID = "985266740114305024".freeze
  GATINEAU, GAME_OF_INCHES, VERSATERM = LEAGUE_IDS = %w[1394035501555519488 1388688738330087424 1364640872536211456].freeze

  def sleeper_fixture(name)
    Rails.root.join("test/fixtures/files/sleeper", name).read
  end

  def sleeper_json(name) = JSON.parse(sleeper_fixture(name))

  def stub_sleeper(path, fixture = nil, base: SLEEPER_BASE, body: nil, status: 200)
    stub_request(:get, %r{\A#{Regexp.escape(base + path)}(\?.*)?\z})
      .to_return(status:, body: body || sleeper_fixture(fixture), headers: { "Content-Type" => "application/json" })
  end

  def create_account
    Account.create!(sleeper_username: "kingarrage", sleeper_user_id: MY_USER_ID)
  end

  def stub_all_leagues(week: 9)
    stub_sleeper("/user/#{MY_USER_ID}/leagues/nfl/2026", "leagues_2026.json")
    LEAGUE_IDS.each do |id|
      stub_sleeper("/league/#{id}/users", "users_#{id}.json")
      stub_sleeper("/league/#{id}/rosters", "rosters_#{id}.json")
      (1..week).each do |w|
        stub_sleeper("/league/#{id}/matchups/#{w}", "matchups_#{id}_#{w}.json")
        stub_sleeper("/league/#{id}/transactions/#{w}", "transactions_#{id}_#{w}.json")
      end
    end
  end

  def stub_players = stub_sleeper("/players/nfl", "players_trimmed.json")

  def stub_projections(weeks = 9..17)
    weeks.each { |w| stub_sleeper("/projections/nfl/2026/#{w}", "projections_2026_#{w}.json", base: PROJECTIONS_BASE) }
  end

  # Full sync against the recorded fixtures: account, players, leagues for a week.
  def sync_fixture_leagues(week: 9)
    create_account
    stub_sleeper("/state/nfl", "state.json")
    stub_sleeper("/players/nfl/trending/add", "trending_add.json")
    stub_players
    stub_all_leagues(week:)
    Sync::Players.new(client: sleeper_client).call
    Sync::Leagues.new(client: sleeper_client).call(season: 2026, week:)
  end

  def sync_fixture_projections
    stub_projections
    Sync::Projections.new(source: Sleeper::ProjectionsSource.new(retry_interval: 0)).call(season: 2026, from_week: 9, to_week: 17)
  end

  def sleeper_client = Sleeper::Client.new(retry_interval: 0)
end
