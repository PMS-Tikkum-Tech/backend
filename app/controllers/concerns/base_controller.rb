# frozen_string_literal: true

module BaseController
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    rescue_from ActionController::ParameterMissing, with: :render_missing_param
    rescue_from JWT::DecodeError, with: :render_invalid_token
    rescue_from JWT::ExpiredSignature, with: :render_expired_token
  end

  private

  def render_success(message:, data: nil, meta: nil, status: :ok)
    payload = {
      success: true,
      message: message,
    }
    payload[:data] = data if data
    payload[:meta] = meta if meta

    render json: payload, status: status
  end

  def render_error(message:, errors: nil, status: :unprocessable_entity)
    payload = {
      success: false,
      message: message,
    }
    payload[:errors] = errors if errors

    render json: payload, status: status
  end

  def current_user
    return @current_user if defined?(@current_user)

    token = bearer_token
    return @current_user = nil unless token

    payload = decode_jwt(token)
    return @current_user = nil if RevokedToken.exists?(jti: payload["jti"])

    @current_user = User.find_by(id: payload["user_id"])
  rescue ActiveRecord::RecordNotFound
    @current_user = nil
  end

  def authenticate_user!
    return if current_user

    render_error(
      message: "Authentication required",
      status: :unauthorized,
    )
  end

  def bearer_token
    auth_header = request.headers["Authorization"].to_s
    return nil unless auth_header.start_with?("Bearer ")

    auth_header.split(" ", 2).last
  end

  def decode_jwt(token)
    JWT.decode(
      token,
      JWT_SECRET_KEY,
      true,
      algorithm: "HS256",
    ).first
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value,
    }
  end

  def render_record_not_found(exception)
    render_error(
      message: "Resource not found",
      errors: [exception.message],
      status: :not_found,
    )
  end

  def render_forbidden
    render_error(
      message: "You are not authorized to perform this action",
      status: :forbidden,
    )
  end

  def render_missing_param(exception)
    render_error(
      message: "Validation failed",
      errors: [exception.message],
      status: :unprocessable_entity,
    )
  end

  def render_invalid_token
    render_error(
      message: "Invalid authentication token",
      status: :unauthorized,
    )
  end

  def render_expired_token
    render_error(
      message: "Authentication token has expired",
      status: :unauthorized,
    )
  end
end
