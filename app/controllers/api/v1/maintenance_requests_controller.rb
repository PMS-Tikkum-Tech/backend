# frozen_string_literal: true

require "csv"

module Api
  module V1
    class MaintenanceRequestsController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :set_request, only: [:show, :update, :destroy]

      def index
        ensure_admin_role!
        return if performed?

        requests = base_scope
        requests = apply_filters(requests)
        requests = apply_sort(requests)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 8).to_i, 100].min
        paginated = requests.page(page).per(per_page)

        render_success(
          message: "Maintenance requests retrieved successfully",
          data: MaintenanceRequestPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def show
        unless can_view_request?(@request)
          return render_error(
            message: "Forbidden",
            errors: ["You cannot access this maintenance request"],
            status: :forbidden,
          )
        end

        render_success(
          message: "Maintenance request retrieved successfully",
          data: MaintenanceRequestPresenter.as_json(@request),
        )
      end

      def create
        request = MaintenanceRequest.new(create_attributes)

        unless request.save
          return render_error(
            message: "Validation failed",
            errors: request.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        actor = current_user.admin? ? current_user : nil
        if actor
          LogActivities::LogActivityService.log(
            admin: actor,
            action: "create",
            module_name: "Maintenance",
            description: "Created maintenance request ##{request.id}",
          )
        end

        render_success(
          message: "Maintenance request created successfully",
          data: MaintenanceRequestPresenter.as_json(request),
          status: :created,
        )
      end

      def update
        ensure_admin_role!
        return if performed?

        @request.assign_attributes(update_attributes)

        unless @request.save
          return render_error(
            message: "Validation failed",
            errors: @request.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Maintenance",
          description: "Updated maintenance request ##{@request.id}",
        )

        render_success(
          message: "Maintenance request updated successfully",
          data: MaintenanceRequestPresenter.as_json(@request),
        )
      end

      def destroy
        ensure_admin_role!
        return if performed?

        id = @request.id
        @request.destroy!

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "delete",
          module_name: "Maintenance",
          description: "Deleted maintenance request ##{id}",
        )

        render_success(message: "Maintenance request deleted successfully")
      end

      def export
        ensure_admin_role!
        return if performed?

        requests = apply_sort(apply_filters(base_scope))

        csv_data = CSV.generate(headers: true) do |csv|
          csv << [
            "Date",
            "Property",
            "Unit",
            "Tenant",
            "Issue",
            "Category",
            "Priority",
            "Status",
            "Technician",
          ]

          requests.find_each do |request|
            csv << [
              request.requested_date,
              request.property&.name,
              request.unit&.name,
              request.tenant&.full_name,
              request.issue,
              request.category,
              request.priority,
              request.status,
              request.assigned_to&.full_name,
            ]
          end
        end

        send_data(
          csv_data,
          filename: "maintenance-requests.csv",
          type: "text/csv",
        )
      end

      private

      def base_scope
        MaintenanceRequest.includes(:property, :unit, :tenant, :assigned_to)
      end

      def set_request
        @request = base_scope.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Maintenance request not found",
          errors: ["Maintenance request not found"],
          status: :not_found,
        )
      end

      def ensure_admin_role!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can access this endpoint"],
          status: :forbidden,
        )
      end

      def can_view_request?(request)
        return false unless request
        return true if current_user.admin?

        current_user.tenant? && request.tenant_id == current_user.id
      end

      def create_attributes
        attrs = maintenance_request_params.to_h.symbolize_keys

        if current_user.admin?
          attrs
        else
          attrs.merge(tenant_id: current_user.id)
        end
      end

      def update_attributes
        maintenance_request_params.to_h.symbolize_keys
      end

      def maintenance_request_params
        permitted = params.require(:maintenance_request).permit(
          :property_id,
          :unit_id,
          :tenant_id,
          :assigned_to_id,
          :issue,
          :category,
          :description,
          :priority,
          :status,
          :requested_date,
          :repair_date,
          :visiting_hours,
        )

        if current_user.admin?
          permitted
        else
          permitted.except(:tenant_id, :assigned_to_id, :status)
        end
      end

      def apply_filters(scope)
        filtered = scope

        if params[:property_id].present?
          filtered = filtered.where(property_id: params[:property_id])
        end

        filtered = filtered.where(status: params[:status]) if params[:status].present?
        filtered = filtered.where(priority: params[:priority]) if params[:priority].present?
        filtered = filtered.where(category: params[:category]) if params[:category].present?

        if params[:unit_type].present?
          filtered = filtered.joins(:unit).where(units: { unit_type: params[:unit_type] })
        end

        if params[:search].present?
          term = "%#{params[:search]}%"
          filtered = filtered.joins(:tenant)
                             .where(
                               "maintenance_requests.issue ILIKE ? OR " \
                               "users.full_name ILIKE ?",
                               term,
                               term,
                             )
        end

        filtered
      end

      def apply_sort(scope)
        case params[:sort]
        when "oldest"
          scope.order(created_at: :asc)
        else
          scope.order(created_at: :desc)
        end
      end
    end
  end
end
