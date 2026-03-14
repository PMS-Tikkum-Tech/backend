# frozen_string_literal: true

module Api
  module V1
    class UnitsController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :ensure_admin!
      before_action :set_unit, only: [:show, :update, :destroy]
      before_action :set_property, only: [:index_by_property]
      before_action :set_owner, only: [:index_by_owner]

      def index
        units = Unit.includes(:property, current_lease: :tenant)
        units = apply_filters(units)
        units = apply_sort(units)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 10).to_i, 100].min
        paginated = units.page(page).per(per_page)

        render_success(
          message: "Units retrieved successfully",
          data: UnitPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def show
        render_success(
          message: "Unit retrieved successfully",
          data: UnitPresenter.as_json(@unit),
        )
      end

      def index_by_property
        units = Unit.includes(:property, current_lease: :tenant)
                    .where(property_id: @property.id)
        units = apply_filters(units)
        units = apply_sort(units)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 10).to_i, 100].min
        paginated = units.page(page).per(per_page)

        render_success(
          message: "Units retrieved successfully",
          data: UnitPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def index_by_owner
        units = Unit.includes(:property, current_lease: :tenant)
                    .joins(:property)
                    .where(properties: { user_id: @owner.id })
        units = apply_filters(units)
        units = apply_sort(units)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 10).to_i, 100].min
        paginated = units.page(page).per(per_page)

        render_success(
          message: "Units retrieved successfully",
          data: UnitPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def create
        unit = Unit.new(unit_params.except(:photos, :roomphotos))
        attach_photos(unit)

        unless unit.save
          return render_error(
            message: "Validation failed",
            errors: unit.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "create",
          module_name: "Unit",
          description: "Created unit: #{unit.name}",
        )

        render_success(
          message: "Unit created successfully",
          data: UnitPresenter.as_json(unit),
          status: :created,
        )
      end

      def update
        @unit.assign_attributes(unit_params.except(:photos, :roomphotos))
        attach_photos(@unit)

        unless @unit.save
          return render_error(
            message: "Validation failed",
            errors: @unit.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Unit",
          description: "Updated unit: #{@unit.name}",
        )

        render_success(
          message: "Unit updated successfully",
          data: UnitPresenter.as_json(@unit),
        )
      end

      def destroy
        name = @unit.name
        @unit.destroy!

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "delete",
          module_name: "Unit",
          description: "Deleted unit: #{name}",
        )

        render_success(message: "Unit deleted successfully")
      end

      private

      def ensure_admin!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can manage units"],
          status: :forbidden,
        )
      end

      def set_unit
        @unit = Unit.includes(:property, current_lease: :tenant).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Unit not found",
          errors: ["Unit not found"],
          status: :not_found,
        )
      end

      def set_property
        @property = Property.find(params[:property_id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Property not found",
          errors: ["Property not found"],
          status: :not_found,
        )
      end

      def set_owner
        @owner = User.owner.find(params[:owner_id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Owner not found",
          errors: ["Owner not found"],
          status: :not_found,
        )
      end

      def unit_params
        params.require(:unit).permit(
          :property_id,
          :name,
          :unit_type,
          :status,
          :people_allowed,
          :price,
          :roomphotos,
          roomphotos: [],
          photos: [],
        )
      end

      def apply_filters(scope)
        filtered = scope

        if params[:property_id].present?
          filtered = filtered.where(property_id: params[:property_id])
        end

        if params[:status].present?
          filtered = filtered.where(status: params[:status])
        end

        if params[:unit_type].present?
          filtered = filtered.where(unit_type: params[:unit_type])
        end

        if params[:search].present?
          term = "%#{params[:search]}%"
          filtered = filtered.where("units.name ILIKE ?", term)
        end

        filtered
      end

      def apply_sort(scope)
        case params[:sort]
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

      def attach_photos(unit)
        photos = extract_roomphotos
        return unless photos.present?

        photos.each { |photo| unit.photos.attach(photo) }
      end

      def extract_roomphotos
        raw_photos = unit_params[:roomphotos].presence || unit_params[:photos]
        return [] unless raw_photos.present?
        return raw_photos.reject(&:blank?) if raw_photos.is_a?(Array)

        [raw_photos].reject(&:blank?)
      end
    end
  end
end
