# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :ensure_admin!
      before_action :set_payment, only: [:show, :update, :destroy, :push_invoice]

      def index
        mark_overdue_payments!

        payments = Payment.includes(:property, :unit, :tenant, :lease)
        payments = apply_filters(payments)
        payments = apply_sort(payments)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 8).to_i, 100].min
        paginated = payments.page(page).per(per_page)

        render_success(
          message: "Payments retrieved successfully",
          data: PaymentPresenter.collection(paginated),
          meta: pagination_meta(paginated),
        )
      end

      def show
        @payment.check_overdue!

        render_success(
          message: "Payment retrieved successfully",
          data: PaymentPresenter.as_json(@payment),
        )
      end

      def create
        payment = Payment.new(payment_params)

        unless payment.save
          return render_error(
            message: "Validation failed",
            errors: payment.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "create",
          module_name: "Payment",
          description: "Created payment #{payment.invoice_id}",
        )

        render_success(
          message: "Payment created successfully",
          data: PaymentPresenter.as_json(payment),
          status: :created,
        )
      end

      def update
        @payment.assign_attributes(payment_params)

        unless @payment.save
          return render_error(
            message: "Validation failed",
            errors: @payment.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Payment",
          description: "Updated payment #{@payment.invoice_id}",
        )

        render_success(
          message: "Payment updated successfully",
          data: PaymentPresenter.as_json(@payment),
        )
      end

      def destroy
        invoice_id = @payment.invoice_id
        @payment.destroy!

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "delete",
          module_name: "Payment",
          description: "Deleted payment #{invoice_id}",
        )

        render_success(message: "Payment deleted successfully")
      end

      def push_invoice
        response = @payment.push_to_xendit
        unless response[:success]
          return render_error(
            message: "Failed to push invoice",
            errors: [response[:error].presence || "Unknown error"],
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Payment",
          description: "Pushed payment #{@payment.invoice_id} to Xendit",
        )

        render_success(
          message: "Invoice pushed successfully",
          data: PaymentPresenter.as_json(@payment.reload),
        )
      end

      private

      def ensure_admin!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can manage payments"],
          status: :forbidden,
        )
      end

      def set_payment
        @payment = Payment.includes(:property, :unit, :tenant, :lease).find(
          params[:id],
        )
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Payment not found",
          errors: ["Payment not found"],
          status: :not_found,
        )
      end

      def payment_params
        params.require(:payment).permit(
          :property_id,
          :unit_id,
          :tenant_id,
          :lease_id,
          :status,
          :amount,
          :due_date,
          :paid_at,
          :payment_method,
          :description,
        )
      end

      def apply_filters(scope)
        filtered = scope

        if params[:property_id].present?
          filtered = filtered.where(property_id: params[:property_id])
        end

        if params[:unit_id].present?
          filtered = filtered.where(unit_id: params[:unit_id])
        end

        if params[:tenant_id].present?
          filtered = filtered.where(tenant_id: params[:tenant_id])
        end

        filtered = filtered.where(status: params[:status]) if params[:status].present?

        if params[:due_from].present?
          filtered = filtered.where("due_date >= ?", params[:due_from])
        end

        if params[:due_to].present?
          filtered = filtered.where("due_date <= ?", params[:due_to])
        end

        if params[:search].present?
          term = "%#{params[:search]}%"
          filtered = filtered.where("invoice_id ILIKE ?", term)
        end

        filtered
      end

      def apply_sort(scope)
        case params[:sort]
        when "oldest"
          scope.order(created_at: :asc)
        when "due_date"
          scope.order(due_date: :asc)
        else
          scope.order(created_at: :desc)
        end
      end

      def mark_overdue_payments!
        Payment.waiting.where("due_date < ?", Date.current).find_each(&:check_overdue!)
      end
    end
  end
end
