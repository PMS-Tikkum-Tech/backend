class Api::V1::HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def index
    render json: {
      status: 'ok',
      service: 'PMS Tikkum Tech API',
      version: 'v1',
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
  end
end
