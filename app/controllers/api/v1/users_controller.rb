# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      include BaseController

      before_action :authenticate_user!

      def index
        render_user_listing(filter_params)
      end

      def tenant
        render_user_listing(filter_params.merge(role: "tenant"))
      end

      def admin
        render_user_listing(filter_params.merge(role: "admin"))
      end

      def owner
        render_user_listing(filter_params.merge(role: "owner"))
      end

      def show
        result = Users::ShowService.new(
          current_user: current_user,
          id: params[:id],
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: UserPresenter.as_json(result.data),
        )
      end

      def create
        input = UserInput.from_create_params(user_params)
        return render_input_errors(input, :create) if input.invalid?(:create)

        result = Users::CreateService.new(
          current_user: current_user,
          params: input.to_create_h,
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: UserPresenter.as_json(result.data),
          status: :created,
        )
      end

      def update
        input = UserInput.from_update_params(user_params)
        return render_input_errors(input, :update) if input.invalid?(:update)

        result = Users::UpdateService.new(
          current_user: current_user,
          id: params[:id],
          params: input.to_update_h,
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: UserPresenter.as_json(result.data),
        )
      end

      def destroy
        result = Users::DeleteService.new(
          current_user: current_user,
          id: params[:id],
        ).call
        return render_service_failure(result) unless result.success?

        render_success(message: result.message)
      end

      private

      def user_params
        params.require(:user).permit(
          :full_name,
          :email,
          :password,
          :phone_number,
          :emergency_contact_name,
          :emergency_contact_number,
          :relationship,
          :nik,
          :role,
          :account_status,
          :profile_picture,
        )
      end

      def filter_params
        params.permit(:search, :role, :account_status, :page, :per_page)
      end

      def render_input_errors(input, context)
        input.valid?(context)
        render_error(
          message: "Validation failed",
          errors: input.errors.full_messages,
          status: :unprocessable_entity,
        )
      end

      def render_service_failure(result)
        status = if result.message == "Forbidden"
                   :forbidden
                 elsif result.message == "User not found"
                   :not_found
                 else
                   :unprocessable_entity
                 end

        render_error(
          message: result.message,
          errors: result.errors,
          status: status,
        )
      end

      def render_user_listing(listing_params)
        input = UserInput.from_filter_params(listing_params)
        result = Users::ListService.new(
          current_user: current_user,
          params: input.to_filter_h,
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: UserPresenter.collection(result.data[:users]),
          meta: result.data[:pagination],
        )
      end
    end
  end
end
