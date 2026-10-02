require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "renders the settings button" do
    get root_path

    assert_response :success
    assert_select ".home-settings__button"
  end
end
