# frozen_string_literal: true

module Properties
  class TenantsService < BasePropertiesService
    def initialize(current_user:, property_id:, params: {})
      super(current_user: current_user, params: params)
      @property_id = property_id
    end

    def call
      ensure_admin!

      property = Property.find(@property_id)
      leases = property.leases.includes(:tenant, :unit).active
      leases = apply_filters(leases)
      leases = apply_created_sort(leases, @params[:sort])

      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 5).to_i, 10_000].min
      paginated = leases.page(page).per(per_page)

      success(
        data: {
          property: property,
          leases: paginated,
          pagination: pagination_meta(paginated),
        },
        message: "Property tenants retrieved successfully",
      )
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to list tenants")
    end

    private

    def apply_filters(scope)
      filtered = scope
      filtered = filtered.where(payment_status: @params[:status]) if @params[:status].present?

      if @params[:unit_type].present?
        filtered = filtered.joins(:unit).where(units: { unit_type: @params[:unit_type] })
      end

      if @params[:search].present?
        term = "%#{@params[:search]}%"
        filtered = filtered.joins(:tenant).where("users.full_name ILIKE ?", term)
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
