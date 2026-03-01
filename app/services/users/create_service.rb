# frozen_string_literal: true

module Users
  class CreateService < BaseUsersService
    def call
      ensure_admin!

      user = User.new(
        full_name: @params[:full_name],
        email: @params[:email],
        password: @params[:password],
        phone_number: @params[:phone_number],
        emergency_contact_name: @params[:emergency_contact_name],
        emergency_contact_number: @params[:emergency_contact_number],
        relationship: @params[:relationship],
        nik: @params[:nik],
        role: normalize_role(@params[:role]) || "tenant",
        account_status: normalize_account_status(@params[:account_status]) ||
                        "active",
      )

      user.profile_picture.attach(@params[:profile_picture]) if
        @params[:profile_picture].present?

      return validation_failure(user) unless user.save

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "create",
        module_name: "User",
        description: "Created #{user.role} user: #{user.email}",
      )

      success(data: user, message: "User created successfully")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to create user")
    end

    private

    def validation_failure(user)
      failure(errors: user.errors.full_messages, message: "Validation failed")
    end
  end
end
