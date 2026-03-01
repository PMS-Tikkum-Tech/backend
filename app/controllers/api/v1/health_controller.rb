# frozen_string_literal: true

module Api
  module V1
    class HealthController < ApplicationController
      def index
        render json: {
          success: true,
          message: "Kyrastay API is healthy",
          data: {
            timestamp: Time.current.iso8601,
          },
        }
      end
    end
  end
end
