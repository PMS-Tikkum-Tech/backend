# frozen_string_literal: true

# Unified AuthPresenter for all auth and user responses
# Handles login, me, and users collection responses
class AuthPresenter
  include BasePresenter

  # Login response with tokens
  def self.login_response(result, _current_user = nil)
    {
      user: user_data(result[:user]),
      token: result[:token],
      refresh_token: result[:refresh_token],
      expires_at: Time.at(result[:expires_at]).iso8601
    }
  end

  # Single user response
  def self.user_response(user, current_user)
    user_data(user, current_user)
  end

  # Users collection response
  def self.users_collection(result, current_user)
    {
      users: result[:users].map { |u| user_data(u, current_user) },
      pagination: result[:pagination]
    }
  end

  # Build user data hash
  def self.user_data(user, current_user = nil)
    data = {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      phone: current_user&.admin? ? user.phone : nil,
      role: user.role,
      profile_photo_url: user.profile_photo_url,
      created_at: user.created_at.iso8601
    }

    # Include profile photo metadata only if present
    if user.profile_photo_attached?
      data[:profile_photo] = {
        filename: user.profile_photo.filename.to_s,
        content_type: user.profile_photo.content_type,
        size: user.profile_photo.byte_size,
        url: user.profile_photo_url
      }
    end

    data
  end
end
