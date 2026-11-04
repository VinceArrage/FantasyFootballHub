require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "root redirects to setup without an account" do
    get root_path
    assert_redirected_to new_setup_path
  end

  test "linking a username creates the account and starts syncs" do
    stub_sleeper("/user/kingarrage", "user_kingarrage.json")
    assert_enqueued_jobs 3, only: SyncJob do
      post setup_path, params: { username: "KingArrage " }
    end
    assert_redirected_to root_path
    assert_equal MY_USER_ID, Account.current.sleeper_user_id
  end

  test "unknown username shows an error" do
    stub_sleeper("/user/nobody", body: "null")
    post setup_path, params: { username: "nobody" }
    assert_response :unprocessable_entity
    assert_nil Account.current
  end
end
