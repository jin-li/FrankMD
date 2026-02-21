if ENV["OIDC_CLIENT_ID"].present? && ENV["OIDC_CLIENT_SECRET"].present? && ENV["OIDC_ISSUER"].present?
  require "omniauth_openid_connect"
  require "omniauth/rails_csrf_protection"

  sanitize_env_url = ->(value) do
    normalized = value.to_s.strip
    normalized = normalized.gsub(/\A[\[\(\{\s"']+|[\]\)\}\s"']+\z/, "")
    normalized = normalized.split(",").first.to_s.strip
    normalized.gsub(/\A["']+|["']+\z/, "")
  end

  oidc_issuer = sanitize_env_url.call(ENV.fetch("OIDC_ISSUER"))
  oidc_redirect_uri = sanitize_env_url.call(
    ENV["OIDC_REDIRECT_URI"].presence ||
    ENV["OIDC_REDIRECT_URIS"].presence ||
    "#{ENV.fetch("APP_URL", "http://localhost:3000")}/auth/openid_connect/callback"
  )

  Rails.logger.info("[OIDC] issuer=#{oidc_issuer} redirect_uri=#{oidc_redirect_uri} client_id=#{ENV.fetch("OIDC_CLIENT_ID")}")

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect,
      name: :openid_connect,
      scope: [ :openid, :email, :profile ],
      response_type: :code,
      issuer: oidc_issuer,
      discovery: true,
      client_auth_method: :post,
      client_options: {
        identifier: ENV.fetch("OIDC_CLIENT_ID"),
        secret: ENV.fetch("OIDC_CLIENT_SECRET"),
        redirect_uri: oidc_redirect_uri
      }
  end

  OmniAuth.config.allowed_request_methods = [ :post, :get ]
  OmniAuth.config.logger = Rails.logger
end
