# frozen_string_literal: true

module Users
  class ShowService < BaseUsersService
    def initialize(current_user:, id:)
      super(current_user: current_user, params: {})
      @id = id
    end

    def call
      ensure_admin!

      user = User.find(@id)
      success(data: user, message: "User retrieved successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["User not found"], message: "User not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to retrieve user")
    end
  end
end
