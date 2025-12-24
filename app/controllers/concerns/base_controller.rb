# frozen_string_literal: true

# Base Controller concern for API controllers
# Provides standard response methods and authentication helpers
module BaseController
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from StandardError, with: :handle_standard_error
  end

  private

  # Render successful JSON response
  def render_success(message, data = nil, status = :ok)
    response = {
      success: true,
      message: message
    }
    response[:data] = data if data

    render(json: response, status: status)
  end

  # Render error JSON response
  def render_error(message, errors = nil, status = :unprocessable_entity)
    response = {
      success: false,
      message: message
    }
    response[:errors] = errors if errors

    render(json: response, status: status)
  end

  # Render unauthorized response
  def render_unauthorized(message = 'Unauthorized')
    render_error(message, nil, :unauthorized)
  end

  # Render not found response
  def render_not_found(message = 'Resource not found')
    render_error(message, nil, :not_found)
  end

  # Handle Pundit authorization errors
  def user_not_authorized(exception)
    render_unauthorized('You are not authorized to perform this action')
  end

  # Handle record not found errors
  def record_not_found(exception)
    render_not_found(exception.message)
  end

  # Handle standard errors
  def handle_standard_error(exception)
    Rails.logger.error("Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    render_error('An unexpected error occurred', [exception.message],
                 :internal_server_error)
  end

  # Extract user from JWT token
  def current_user
    return @current_user if defined?(@current_user)

    token = request.headers['Authorization']&.sub(/^Bearer /, '')
    return nil unless token

    decoded = decode_jwt(token)
    return nil unless decoded

    # Check if token is blacklisted
    jti = decoded[0]['jti']
    return nil if token_blacklisted?(jti)

    @current_user = User.find_by(id: decoded[0]['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  # Check if user is authenticated
  def authenticate_user!
    return if current_user

    render_unauthorized('Authentication required')
  end

  # Decode JWT token
  def decode_jwt(token)
    JWT.decode(token, ENV['JWT_SECRET_KEY'], true, { algorithm: 'HS256' })
  end

  # Check if token is blacklisted
  def token_blacklisted?(jti)
    return false unless jti

    RevokedToken.where(jti: jti).exists?
  end

  # Helper method to check if current user is admin
  def current_user_admin?
    current_user&.admin?
  end
end
