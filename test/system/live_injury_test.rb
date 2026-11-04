require "application_system_test_case"

class LiveInjuryTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sync_fixture_leagues
    WebMock.disable_net_connect!(allow_localhost: true, allow: [ /chromedriver/, /googlechromelabs/, /storage\.googleapis/ ])
  end

  teardown { WebMock.disable_net_connect!(allow_localhost: true) }

  test "an injury change appears on the open dashboard without a reload" do
    player = League.find_by(sleeper_id: GATINEAU).my_team.starters.first
    player.update!(injury_status: nil)
    visit root_path
    assert_selector "#injury_feed"
    sleep 1 # let the cable subscriptions connect

    player.update!(injury_status: "Out")
    perform_enqueued_jobs { Injuries::Recorder.call([ { player:, from: nil, to: "Out" } ]) }

    within("#injury_feed") { assert_text player.full_name }
    assert_text "Healthy → Out"
  end
end
