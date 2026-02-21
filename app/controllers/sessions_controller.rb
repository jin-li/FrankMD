class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :failure ]

  def new
    # This will redirect to the OIDC provider
    redirect_to "/auth/openid_connect", allow_other_host: true
  end

  def create
    # OmniAuth callback handler
    auth_hash = request.env["omniauth.auth"]

    if auth_hash.present?
      session[:user_info] = {
        uid: auth_hash["uid"],
        email: auth_hash.dig("info", "email"),
        name: auth_hash.dig("info", "name"),
        token: auth_hash.dig("credentials", "token"),
        expires_at: auth_hash.dig("credentials", "expires_at")
      }

      redirect_to root_path, notice: "Successfully authenticated!"
    else
      redirect_to login_path, alert: "Authentication failed"
    end
  end

  def destroy
    # Clear the session
    session.delete(:user_info)

    # Redirect to OIDC provider logout if configured
    oidc_logout_url = ENV["OIDC_LOGOUT_URL"]
    if oidc_logout_url.present?
      redirect_to oidc_logout_url, allow_other_host: true
    else
      redirect_to login_path, notice: "Logged out successfully"
    end
  end

  def failure
    # Handle authentication failure
    redirect_to login_path, alert: "Authentication failed: #{params[:message]}"
  end
end
