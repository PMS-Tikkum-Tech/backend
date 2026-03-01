# frozen_string_literal: true

module Api
  module V1
    class LogActivitiesController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :ensure_admin!
      before_action :set_log_activity, only: [:show]

      def index
        logs = LogActivity.includes(:admin)
        logs = apply_filters(logs)
        logs = apply_sort(logs)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 12).to_i, 100].min
        paginated = logs.page(page).per(per_page)

        render_success(
          message: "Log activities retrieved successfully",
          data: LogActivityPresenter.collection(paginated),
          meta: pagination_meta(paginated).merge(showing_meta(paginated)),
        )
      end

      def show
        render_success(
          message: "Log activity retrieved successfully",
          data: LogActivityPresenter.as_json(@log_activity, detail: true),
        )
      end

      private

      def ensure_admin!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can access log activities"],
          status: :forbidden,
        )
      end

      def set_log_activity
        @log_activity = LogActivity.includes(:admin).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Log activity not found",
          errors: ["Log activity not found"],
          status: :not_found,
        )
      end

      def apply_filters(scope)
        filtered = scope

        if module_filters.any?
          filtered = filtered.where(
            "LOWER(log_activities.module_name) IN (?)",
            module_filters,
          )
        end

        if params[:admin_id].present?
          filtered = filtered.where(admin_id: params[:admin_id])
        end

        if params[:admin_name].present?
          filtered = filtered.joins(:admin).where(
            "users.full_name ILIKE ?",
            "%#{params[:admin_name]}%",
          )
        end

        if action_filter.present?
          filtered = filtered.where(
            "LOWER(log_activities.action) = ?",
            action_filter,
          )
        end

        if params[:date_from].present?
          filtered = filtered.where(
            "log_activities.created_at >= ?",
            params[:date_from],
          )
        end

        if params[:date_to].present?
          filtered = filtered.where(
            "log_activities.created_at <= ?",
            params[:date_to],
          )
        end

        if search_term.present?
          term = "%#{search_term}%"
          filtered = filtered.joins(:admin)
                             .where(
                               "log_activities.description ILIKE :term OR " \
                               "users.full_name ILIKE :term OR " \
                               "log_activities.module_name ILIKE :term OR " \
                               "log_activities.action ILIKE :term",
                               term: term,
                             )
        end

        filtered
      end

      def apply_sort(scope)
        case params[:sort]
        when "oldest", "timestamp_asc"
          scope.order(created_at: :asc)
        else
          scope.order(created_at: :desc)
        end
      end

      def module_filters
        raw_value = params[:module_name].presence || params[:module_page].presence
        normalized = raw_value.to_s.strip.downcase
        return [] if normalized.blank?

        map = {
          "transaction" => "financial",
          "financial report" => "financial",
        }
        values = [normalized]
        mapped = map[normalized]
        values << mapped if mapped.present?
        values.uniq
      end

      def search_term
        params[:search].presence || params[:q].presence
      end

      def action_filter
        raw_value = params[:log_action].presence ||
                    request.query_parameters["action"].presence
        raw_value.to_s.strip.downcase.presence
      end

      def showing_meta(collection)
        total = collection.total_count
        if total.zero? || collection.size.zero?
          return {
            showing_from: 0,
            showing_to: 0,
          }
        end

        from = ((collection.current_page - 1) * collection.limit_value) + 1
        to = [from + collection.size - 1, total].min

        {
          showing_from: from,
          showing_to: to,
        }
      end
    end
  end
end
