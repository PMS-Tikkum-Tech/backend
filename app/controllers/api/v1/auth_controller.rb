# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      include BaseController

      before_action :authenticate_user!, only: [:me, :logout]

      def login
        input = AuthInput.from_params(login_params)
        return render_validation_error(input) if input.invalid?

        result = AuthService.new(params: input.to_h).login
        return render_auth_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: AuthPresenter.login_response(result.data),
        )
      end

      def me
        result = AuthService.new(current_user: current_user).me
        return render_auth_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: UserPresenter.as_json(result.data),
        )
      end

      def logout
        result = AuthService.new(
          current_user: current_user,
          token: bearer_token,
        ).logout
        return render_auth_failure(result) unless result.success?

        render_success(message: result.message)
      end

      private

      def login_params
        params.permit(:email, :password)
      end

      def render_validation_error(input)
        render_error(
          message: "Validation failed",
          errors: input.errors.full_messages,
          status: :unprocessable_entity,
        )
      end

      def render_auth_failure(result)
        render_error(
          message: result.message,
          errors: result.errors,
          status: :unauthorized,
        )
      end
    end
  end
end
