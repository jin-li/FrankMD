require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Mock OIDC configuration
    ENV["OIDC_CLIENT_ID"] = "test-client-id"
  end

  teardown do
    ENV.delete("OIDC_CLIENT_ID")
  end

  test "should redirect to OIDC provider on new" do
    get login_path
    assert_response :redirect
    assert_redirected_to "/auth/openid_connect"
  end

  test "should create session with valid auth hash" do
    auth_hash = {
      "uid" => "12345",
      "info" => {
        "email" => "user@example.com",
        "name" => "Test User"
      },
      "credentials" => {
        "token" => "test-token",
        "expires_at" => 1.hour.from_now.to_i
      }
    }

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(auth_hash)

    get "/auth/openid_connect/callback"

    assert_response :redirect
    assert_redirected_to root_path
    assert_not_nil session[:user_info]
    assert_equal "user@example.com", session[:user_info][:email]

    OmniAuth.config.test_mode = false
  end

  test "should destroy session on logout" do
    # Set up a session
    session[:user_info] = {
      uid: "12345",
      email: "user@example.com",
      name: "Test User"
    }

    get logout_path

    assert_nil session[:user_info]
    assert_response :redirect
  end

  test "should handle authentication failure" do
    get auth_failure_path, params: { message: "invalid_credentials" }

    assert_response :redirect
    assert_redirected_to login_path
    assert_match(/Authentication failed/, flash[:alert])
  end
end
