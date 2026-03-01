# frozen_string_literal: true

module Properties
  class UpdateService < BasePropertiesService
    def initialize(current_user:, id:, params:)
      super(current_user: current_user, params: params)
      @id = id
    end

    def call
      ensure_admin!

      property = Property.find(@id)
      property.assign_attributes(property_attributes)
      attach_photos(property)

      return validation_failure(property) unless property.save

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "update",
        module_name: "Property",
        description: "Updated property: #{property.name}",
      )

      success(data: property, message: "Property updated successfully")
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to update property")
    end

    private

    def property_attributes
      {
        user_id: @params[:user_id],
        name: @params[:name],
        description: @params[:description],
        address: @params[:address],
        property_type: @params[:property_type],
        condition: @params[:condition],
        rules: @params[:rules],
        facilities: @params[:facilities],
      }.compact
    end

    def attach_photos(property)
      roomphotos = @params[:roomphotos].presence || @params[:photos]
      return unless roomphotos.present?

      roomphotos.each do |photo|
        property.photos.attach(photo)
      end
    end

    def validation_failure(property)
      failure(errors: property.errors.full_messages, message: "Validation failed")
    end
  end
end
