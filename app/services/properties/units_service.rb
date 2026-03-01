# frozen_string_literal: true

module Properties
  class UnitsService < BasePropertiesService
    def initialize(current_user:, property_id:, params: {})
      super(current_user: current_user, params: params)
      @property_id = property_id
    end

    def call
      ensure_admin!

      property = Property.find(@property_id)
      units = property.units.includes(current_lease: :tenant)
      units = apply_filters(units)
      units = apply_sort(units)

      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 5).to_i, 10_000].min
      paginated = units.page(page).per(per_page)

      success(
        data: {
          property: property,
          units: paginated,
          pagination: pagination_meta(paginated),
        },
        message: "Property units retrieved successfully",
      )
    rescue ActiveRecord::RecordNotFound
      failure(errors: ["Property not found"], message: "Property not found")
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to list units")
    end

    private

    def apply_filters(scope)
      filtered = scope
      filtered = filtered.where(status: @params[:status]) if @params[:status].present?
      filtered = filtered.where(unit_type: @params[:unit_type]) if @params[:unit_type].present?

      if @params[:search].present?
        term = "%#{@params[:search]}%"
        filtered = filtered.where("name ILIKE ?", term)
      end

      filtered
    end

    def apply_sort(scope)
      case @params[:sort]
      when "oldest"
        scope.order(created_at: :asc)
      when "price_asc"
        scope.order(price: :asc)
      when "price_desc"
        scope.order(price: :desc)
      else
        scope.order(created_at: :desc)
      end
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
