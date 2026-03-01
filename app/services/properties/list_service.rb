# frozen_string_literal: true

module Properties
  class ListService < BasePropertiesService
    def call
      ensure_admin!

      properties = Property.includes(:user, :units, photos_attachments: :blob)
      properties = apply_filters(properties)
      properties = apply_created_sort(properties, @params[:sort])

      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 8).to_i, 100].min
      paginated = properties.page(page).per(per_page)

      success(
        data: {
          properties: paginated,
          pagination: pagination_meta(paginated),
        },
        message: "Properties retrieved successfully",
      )
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to list properties")
    end

    private

    def apply_filters(scope)
      filtered = scope
      if @params[:property_type].present?
        filtered = filtered.by_property_type(@params[:property_type])
      end

      if @params[:condition].present?
        filtered = filtered.by_condition(@params[:condition])
      end

      if @params[:search].present?
        filtered = filtered.search(@params[:search])
      end

      filtered
    end

    def pagination_meta(collection)
      {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value,
      }
    end
  end
end
