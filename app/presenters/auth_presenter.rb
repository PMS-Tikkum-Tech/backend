# frozen_string_literal: true

class AuthPresenter
  def self.login_response(result)
    {
      user: UserPresenter.as_json(result[:user]),
      token: result[:token],
      refresh_token: result[:refresh_token],
      expires_at: result[:expires_at]&.iso8601,
    }
  end
end
