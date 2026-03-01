# frozen_string_literal: true

module Properties
  class MaintenanceService < BasePropertiesService
    def initialize(current_user:, property_id:, params: {})
      super(current_user: current_user, params: params)
      @property_id = property_id
    end

    def call
      ensure_admin!

      property = Property.find(@property_id)
      requests = property.maintenance_requests.includes(:tenant, :unit, :assigned_to)
      requests = apply_filters(requests)
      requests = apply_created_sort(requests, @params[:sort])

      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 6).to_i, 10_000].min
      paginated = requests.page(page).per(per_page)

      success(
        data: {
          property: property,
          maintenance_requests: paginated,
          pagination: pagination_meta(paginated),
        },
        message: "Property maintenance retrieved successfully",
      )
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to list maintenance")
    end

    private

    def apply_filters(scope)
      filtered = scope
      filtered = filtered.where(priority: @params[:priority]) if @params[:priority].present?
      filtered = filtered.where(status: @params[:status]) if @params[:status].present?

      if @params[:unit_type].present?
        filtered = filtered.joins(:unit).where(units: { unit_type: @params[:unit_type] })
      end

      if @params[:search].present?
        term = "%#{@params[:search]}%"
        filtered = filtered.joins(:tenant)
                           .where(
                             "maintenance_requests.issue ILIKE ? OR users.full_name ILIKE ?",
                             term,
                             term,
                           )
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
