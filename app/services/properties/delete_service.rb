# frozen_string_literal: true

module Properties
  class DeleteService < BasePropertiesService
    def initialize(current_user:, id:)
      super(current_user: current_user, params: {})
      @id = id
    end

    def call
      ensure_admin!

      property = Property.find(@id)
      property.destroy!

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "delete",
        module_name: "Property",
        description: "Deleted property: #{property.name}",
      )

      success(data: property, message: "Property deleted successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to delete property")
    end
  end
end
