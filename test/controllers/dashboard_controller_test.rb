require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { sync_fixture_leagues }

  test "shows my three leagues with record and sync stamps" do
    get root_path
    assert_response :success
    %w[Game\ of\ Inches Gatineau\ boys\ 2026 Versaterm\ Fantasy\ League].each { assert_select "h2", text: _1 }
    assert_select "#sync_stamps"
  end

  test "league page shows standings and my roster" do
    league = League.find_by(sleeper_id: GATINEAU)
    get league_path(league)
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(league, :standings)} tbody tr", 12
    assert_select "h2", text: "My roster"
  end
end
