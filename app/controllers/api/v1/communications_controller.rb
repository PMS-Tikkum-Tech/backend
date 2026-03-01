# frozen_string_literal: true

module Api
  module V1
    class CommunicationsController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :ensure_admin!
      before_action :set_communication, only: [:show, :update, :destroy]

      def index
        communications = base_scope
        communications = apply_filters(communications)
        communications = apply_sort(communications)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 10).to_i, 100].min
        paginated = communications.page(page).per(per_page)

        render_success(
          message: "Communications retrieved successfully",
          data: CommunicationPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def show
        render_success(
          message: "Communication retrieved successfully",
          data: CommunicationPresenter.as_json(@communication),
        )
      end

      def create
        communication = Communication.new(
          create_params.merge(created_by: current_user),
        )
        tenant_ids = resolved_tenant_ids(communication)

        if tenant_ids.empty?
          return render_error(
            message: "Validation failed",
            errors: ["No tenant recipients found"],
            status: :unprocessable_entity
          )
        end

        tenant_ids.each do |tenant_id|
          communication.communication_recipients.build(tenant_id: tenant_id)
        end

        unless communication.save
          return render_error(
            message: "Validation failed",
            errors: communication.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "create",
          module_name: "Communication",
          description: "Created communication ##{communication.id}",
        )

        render_success(
          message: "Communication created successfully",
          data: CommunicationPresenter.as_json(communication),
          status: :created,
        )
      end

      def update
        @communication.assign_attributes(update_params)

        if sync_recipients_on_update?
          tenant_ids = resolved_tenant_ids(@communication)
          if tenant_ids.empty?
            return render_error(
              message: "Validation failed",
              errors: ["No tenant recipients found"],
              status: :unprocessable_entity,
            )
          end

          @communication.communication_recipients.destroy_all
          tenant_ids.each do |tenant_id|
            @communication.communication_recipients.build(tenant_id: tenant_id)
          end
        end

        unless @communication.save
          return render_error(
            message: "Validation failed",
            errors: @communication.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        if @communication.scheduled? && @communication.delivery_due?
          SendCommunicationJob.perform_later(@communication.id)
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Communication",
          description: "Updated communication ##{@communication.id}",
        )

        render_success(
          message: "Communication updated successfully",
          data: CommunicationPresenter.as_json(@communication),
        )
      end

      def destroy
        id = @communication.id
        @communication.destroy!

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "delete",
          module_name: "Communication",
          description: "Deleted communication ##{id}",
        )

        render_success(message: "Communication deleted successfully")
      end

      private

      def ensure_admin!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can manage communications"],
          status: :forbidden,
        )
      end

      def set_communication
        @communication = base_scope.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Communication not found",
          errors: ["Communication not found"],
          status: :not_found,
        )
      end

      def base_scope
        Communication.includes(
          :property,
          :created_by,
          communication_recipients: :tenant,
        )
      end

      def create_params
        normalize_schedule_params(
          communication_params.except(:tenant_ids, :send_schedule, :send_now),
        )
      end

      def update_params
        normalize_schedule_params(
          communication_params.except(:tenant_ids, :send_schedule, :send_now),
        )
      end

      def communication_params
        params.require(:communication).permit(
          :property_id,
          :audience_type,
          :status,
          :subject,
          :message,
          :scheduled_at,
          :send_schedule,
          :send_now,
          tenant_ids: [],
        )
      end

      def resolved_tenant_ids(communication)
        audience_type = communication.audience_type

        if audience_type == "all_tenants"
          tenants_for_all_audience(communication).pluck(:id)
        else
          Array(communication_params[:tenant_ids]).reject(&:blank?).map(&:to_i)
        end
      end

      def tenants_for_all_audience(communication)
        scope = User.active_users.tenant

        return scope unless communication.property_id.present?

        scope.joins(leases_as_tenant: { unit: :property })
             .where(units: { property_id: communication.property_id })
             .distinct
      end

      def apply_filters(scope)
        filtered = scope

        if params[:property_id].present?
          filtered = filtered.where(property_id: params[:property_id])
        end

        if params[:status].present?
          filtered = filtered.where(status: params[:status])
        end

        if params[:audience_type].present?
          filtered = filtered.where(audience_type: params[:audience_type])
        end

        if property_type_filter.present?
          filtered = filtered.joins(:property).where(
            "LOWER(properties.property_type) = ?",
            property_type_filter,
          )
        end

        if params[:date_from].present?
          filtered = filtered.where("scheduled_at >= ?", params[:date_from])
        end

        if params[:date_to].present?
          filtered = filtered.where("scheduled_at <= ?", params[:date_to])
        end

        if params[:search].present?
          term = "%#{params[:search]}%"
          filtered = filtered.left_joins(:property).where(
            "communications.subject ILIKE :term OR " \
            "communications.message ILIKE :term OR " \
            "properties.name ILIKE :term",
            term: term,
          )
        end

        filtered.distinct
      end

      def apply_sort(scope)
        case params[:sort]
        when "newest"
          scope.order(created_at: :desc)
        when "oldest"
          scope.order(created_at: :asc)
        when "scheduled_asc"
          scope.order(scheduled_at: :asc, created_at: :asc)
        when "scheduled_desc"
          scope.order(scheduled_at: :desc, created_at: :desc)
        else
          scope.order(created_at: :desc)
        end
      end

      def normalize_schedule_params(attributes)
        params_hash = communication_params
        send_now = ActiveModel::Type::Boolean.new.cast(params_hash[:send_now])
        send_schedule = params_hash[:send_schedule]

        if send_now || send_schedule == "send_now" ||
           attributes[:scheduled_at].blank?
          attributes[:scheduled_at] = Time.current
        end

        attributes[:status] = "scheduled" if attributes[:status].blank?
        attributes
      end

      def sync_recipients_on_update?
        communication_params.key?(:tenant_ids) ||
          communication_params.key?(:audience_type) ||
          communication_params.key?(:property_id)
      end

      def property_type_filter
        raw_value = params[:property_type].presence ||
                    params[:propertyType].presence ||
                    params[:property].presence
        normalize_property_type(raw_value)
      end

      def normalize_property_type(value)
        normalized = value.to_s.strip.downcase.tr(" ", "_")
        return nil if normalized.blank?
        return nil if ["all", "all_property", "all_properties"].include?(
          normalized,
        )

        normalized
      end
    end
  end
end
