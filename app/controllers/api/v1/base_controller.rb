# frozen_string_literal: true

# Base Controller untuk API v1
# Standardizes response format dan common functionality

class Api::V1::BaseController < ApplicationController
  # Skip authentication for specific controllers (like health check)
  skip_before_action :authenticate_user!, only: [:health]
  skip_before_action :verify_authenticity_token

  protected

  def render_success(message, data = nil, status = :ok)
    response = {
      success: true,
      message: message,
      data: data
    }

    render json: response, status: status
  end

  def render_error(message, errors = nil, status = :unprocessable_entity)
    response = {
      success: false,
      message: message
    }

    response[:errors] = errors if errors.present?

    render json: response, status: status
  end

  def render_validation_errors(errors)
    render_error('Validation failed', errors, :unprocessable_entity)
  end

  def render_not_found(message = 'Resource not found')
    render_error(message, nil, :not_found)
  end

  def render_unauthorized(message = 'Unauthorized')
    render_error(message, nil, :unauthorized)
  end

  def render_forbidden(message = 'Forbidden')
    render_error(message, nil, :forbidden)
  end

  def current_user_info
    return nil unless current_user

    {
      id: current_user.id,
      email: current_user.email,
      role: current_user.role,
      full_name: current_user.full_name
    }
  end

  def pagination_params
    {
      page: params[:page]&.to_i || 1,
      per_page: [params[:per_page]&.to_i || 20, 100].min
    }
  end
end