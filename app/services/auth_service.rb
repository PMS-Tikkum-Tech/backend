# frozen_string_literal: true

class AuthService
  include BaseService

  def initialize(current_user: nil, params: {}, token: nil)
    @current_user = current_user
    @params = params
    @token = token
  end

  def login
    user = User.find_by(email: @params[:email].to_s.downcase)
    return invalid_credentials unless user
    return invalid_credentials unless user.authenticate(@params[:password])
    return inactive_account unless user.active?

    tokens = generate_tokens(user)
    user.update!(
      refresh_token: tokens[:refresh_token],
      refresh_token_expires_at: tokens[:refresh_token_expires_at],
    )

    success(
      data: {
        user: user,
        token: tokens[:token],
        refresh_token: tokens[:refresh_token],
        expires_at: tokens[:expires_at],
      },
      message: "Login successful",
    )
  rescue StandardError => exception
    failure(errors: [exception.message], message: "Login failed")
  end

  def me
    return failure(errors: ["Unauthorized"], message: "Unauthorized") unless @current_user

    success(data: @current_user, message: "Profile retrieved")
  end

  def logout
    return failure(errors: ["Unauthorized"], message: "Unauthorized") unless @current_user

    revoke_current_token if @token.present?
    @current_user.update!(refresh_token: nil, refresh_token_expires_at: nil)
    success(message: "Logout successful")
  rescue StandardError => exception
    failure(errors: [exception.message], message: "Logout failed")
  end

  private

  def invalid_credentials
    failure(errors: ["Invalid email or password"], message: "Authentication failed")
  end

  def inactive_account
    failure(errors: ["Account is inactive"], message: "Authentication failed")
  end

  def generate_tokens(user)
    jti = SecureRandom.uuid
    expires_at = JWT_ACCESS_TOKEN_EXPIRATION.from_now
    refresh_token = SecureRandom.uuid

    payload = {
      jti: jti,
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: expires_at.to_i,
    }

    {
      token: JWT.encode(payload, JWT_SECRET_KEY, "HS256"),
      refresh_token: refresh_token,
      refresh_token_expires_at: JWT_REFRESH_TOKEN_EXPIRATION.from_now,
      expires_at: expires_at,
    }
  end

  def revoke_current_token
    payload = JWT.decode(
      @token,
      JWT_SECRET_KEY,
      true,
      algorithm: "HS256",
    ).first

    RevokedToken.create!(
      jti: payload["jti"],
      user: @current_user,
      exp: Time.zone.at(payload["exp"]),
    )
  rescue JWT::DecodeError => exception
    Rails.logger.warn("Unable to revoke token: #{exception.message}")
  end
end
