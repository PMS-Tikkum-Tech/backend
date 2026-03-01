# frozen_string_literal: true

module Users
  class UpdateService < BaseUsersService
    def initialize(current_user:, id:, params:)
      super(current_user: current_user, params: params)
      @id = id
    end

    def call
      ensure_admin!

      user = User.find(@id)
      user.assign_attributes(filtered_user_attributes)
      user.profile_picture.attach(@params[:profile_picture]) if
        @params[:profile_picture].present?

      return validation_failure(user) unless user.save

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "update",
        module_name: "User",
        description: "Updated user: #{user.email}",
      )

      success(data: user, message: "User updated successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["User not found"], message: "User not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to update user")
    end

    private

    def validation_failure(user)
      failure(errors: user.errors.full_messages, message: "Validation failed")
    end

    def filtered_user_attributes
      role = normalize_role(@params[:role])
      status = normalize_account_status(@params[:account_status])

      {
        full_name: @params[:full_name],
        email: @params[:email],
        password: @params[:password],
        phone_number: @params[:phone_number],
        emergency_contact_name: @params[:emergency_contact_name],
        emergency_contact_number: @params[:emergency_contact_number],
        relationship: @params[:relationship],
        nik: @params[:nik],
        role: role,
        account_status: status,
      }.compact
    end
  end
end
