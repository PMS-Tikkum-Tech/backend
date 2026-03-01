# frozen_string_literal: true

module Properties
  class CreateService < BasePropertiesService
    def call
      ensure_admin!

      property = Property.new(property_attributes)
      attach_photos(property)

      return validation_failure(property) unless property.save

      LogActivities::LogActivityService.log(
        admin: @current_user,
        action: "create",
        module_name: "Property",
        description: "Created property: #{property.name}",
      )

      success(data: property, message: "Property created successfully")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to create property")
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
        facilities: @params[:facilities] || [],
      }
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
