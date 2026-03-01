# frozen_string_literal: true

module Properties
  class ShowService < BasePropertiesService
    def initialize(current_user:, id:)
      super(current_user: current_user, params: {})
      @id = id
    end

    def call
      ensure_admin!

      property = Property.includes(
        :user,
        :units,
        :leases,
        photos_attachments: :blob,
      ).find(@id)

      success(data: property, message: "Property retrieved successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to show property")
    end
  end
end
