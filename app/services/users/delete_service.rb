# frozen_string_literal: true

module Users
  class DeleteService < BaseUsersService
    def initialize(current_user:, id:)
      super(current_user: current_user, params: {})
      @id = id
    end

    def call
      ensure_admin!

      user = User.find(@id)
      user.destroy!

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "delete",
        module_name: "User",
        description: "Deleted user: #{user.email}",
      )

      success(data: user, message: "User deleted successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["User not found"], message: "User not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to delete user")
    end
  end
end
