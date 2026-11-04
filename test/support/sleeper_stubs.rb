module SleeperStubs
  SLEEPER_BASE = "https://api.sleeper.app/v1".freeze

  def sleeper_fixture(name)
    Rails.root.join("test/fixtures/files/sleeper", name).read
  end

  def stub_sleeper(path, fixture, base: SLEEPER_BASE)
    stub_request(:get, %r{\A#{Regexp.escape(base + path)}(\?.*)?\z})
      .to_return(status: 200, body: sleeper_fixture(fixture), headers: { "Content-Type" => "application/json" })
  end
end
