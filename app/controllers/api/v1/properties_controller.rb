# frozen_string_literal: true

module Api
  module V1
    class PropertiesController < ApplicationController
      include BaseController

      before_action :authenticate_user!

      def index
        input = PropertyInput.from_filter_params(filter_params)
        result = Properties::ListService.new(
          current_user: current_user,
          params: input.to_filter_h(default_per_page: 8),
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.list(result.data[:properties]),
          meta: result.data[:pagination],
        )
      end

      def show
        result = Properties::ShowService.new(
          current_user: current_user,
          id: params[:id],
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.detail(result.data),
        )
      end

      def create
        input = PropertyInput.from_create_params(property_params)
        return render_input_errors(input, :create) if input.invalid?(:create)

        result = Properties::CreateService.new(
          current_user: current_user,
          params: input.to_create_h,
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.detail(result.data),
          status: :created,
        )
      end

      def update
        input = PropertyInput.from_update_params(property_params)
        return render_input_errors(input, :update) if input.invalid?(:update)

        result = Properties::UpdateService.new(
          current_user: current_user,
          id: params[:id],
          params: input.to_update_h,
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.detail(result.data),
        )
      end

      def destroy
        result = Properties::DeleteService.new(
          current_user: current_user,
          id: params[:id],
        ).call
        return render_service_failure(result) unless result.success?

        render_success(message: result.message)
      end

      def tenants
        result = Properties::TenantsService.new(
          current_user: current_user,
          property_id: params[:id],
          params: tenant_filter_input.to_filter_h(default_per_page: 5),
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.tenant_rows(result.data[:leases]),
          meta: result.data[:pagination],
        )
      end

      def export_tenants
        result = Properties::TenantsService.new(
          current_user: current_user,
          property_id: params[:id],
          params: export_filter_params(default_per_page: 5),
        ).call
        return render_service_failure(result) unless result.success?

        csv_data = Properties::ExportService.tenants_csv(
          PropertyPresenter.tenant_rows(result.data[:leases]),
        )

        send_data(
          csv_data,
          filename: "property-#{params[:id]}-tenants.csv",
          type: "text/csv",
        )
      end

      def units
        result = Properties::UnitsService.new(
          current_user: current_user,
          property_id: params[:id],
          params: unit_filter_input.to_filter_h(default_per_page: 5),
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.unit_rows(result.data[:units]),
          meta: result.data[:pagination],
        )
      end

      def export_units
        result = Properties::UnitsService.new(
          current_user: current_user,
          property_id: params[:id],
          params: export_filter_params(default_per_page: 5),
        ).call
        return render_service_failure(result) unless result.success?

        csv_data = Properties::ExportService.units_csv(
          PropertyPresenter.unit_rows(result.data[:units]),
        )

        send_data(
          csv_data,
          filename: "property-#{params[:id]}-units.csv",
          type: "text/csv",
        )
      end

      def maintenance
        result = Properties::MaintenanceService.new(
          current_user: current_user,
          property_id: params[:id],
          params: maintenance_filter_input.to_filter_h(default_per_page: 6),
        ).call
        return render_service_failure(result) unless result.success?

        render_success(
          message: result.message,
          data: PropertyPresenter.maintenance_rows(
            result.data[:maintenance_requests],
          ),
          meta: result.data[:pagination],
        )
      end

      def export_maintenance
        result = Properties::MaintenanceService.new(
          current_user: current_user,
          property_id: params[:id],
          params: export_filter_params(default_per_page: 6),
        ).call
        return render_service_failure(result) unless result.success?

        csv_data = Properties::ExportService.maintenance_csv(
          PropertyPresenter.maintenance_rows(result.data[:maintenance_requests]),
        )

        send_data(
          csv_data,
          filename: "property-#{params[:id]}-maintenance.csv",
          type: "text/csv",
        )
      end

      private

      def property_params
        params.require(:property).permit(
          :name,
          :description,
          :address,
          :property_type,
          :condition,
          :rules,
          :roomphotos,
          :user_id,
          facilities: [],
          roomphotos: [],
          photos: [],
        )
      end

      def filter_params
        params.permit(
          :property_type,
          :condition,
          :search,
          :sort,
          :page,
          :per_page,
          :status,
          :unit_type,
          :priority,
        )
      end

      def tenant_filter_input
        PropertyInput.from_filter_params(filter_params)
      end

      def unit_filter_input
        PropertyInput.from_filter_params(filter_params)
      end

      def maintenance_filter_input
        PropertyInput.from_filter_params(filter_params)
      end

      def export_filter_params(default_per_page:)
        PropertyInput.from_filter_params(filter_params).to_filter_h(
          default_per_page: default_per_page,
        ).merge(page: 1, per_page: 10_000)
      end

      def render_input_errors(input, context)
        input.valid?(context)

        render_error(
          message: "Validation failed",
          errors: input.errors.full_messages,
          status: :unprocessable_entity,
        )
      end

      def render_service_failure(result)
        status =
          case result.message
          when "Forbidden"
            :forbidden
          when "Property not found"
            :not_found
          else
            :unprocessable_entity
          end

        render_error(
          message: result.message,
          errors: result.errors,
          status: status,
        )
      end
    end
  end
end
