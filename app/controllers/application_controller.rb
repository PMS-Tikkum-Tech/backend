class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pundit::Authorization

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Handle Record Not Found
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # Handle Validation Errors
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  private

  def user_not_authorized(exception)
    render json: {
      error: 'You are not authorized to perform this action.',
      message: exception.message
    }, status: :forbidden
  end

  def record_not_found(exception)
    render json: {
      error: 'Record not found',
      message: exception.message
    }, status: :not_found
  end

  def record_invalid(exception)
    render json: {
      error: 'Validation failed',
      message: exception.message,
      details: exception.record&.errors
    }, status: :unprocessable_entity
  end

  # Helper method for current user info
  def current_user_info
    return nil unless current_user

    {
      id: current_user.id,
      email: current_user.email,
      role: current_user.role,
      first_name: current_user.first_name,
      last_name: current_user.last_name
    }
  end
end
