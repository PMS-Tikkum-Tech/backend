# frozen_string_literal: true

require "cgi"

module Api
  module V1
    class FinancialTransactionsController < ApplicationController
      include BaseController

      before_action :authenticate_user!
      before_action :ensure_admin!
      before_action :set_transaction, only: [:show, :update, :destroy]

      def index
        transactions = apply_filters(base_scope)
        transactions = apply_sort(transactions)

        summary_scope = apply_filters(base_scope, include_category: false)
        summary = build_summary(summary_scope)

        page = (params[:page].presence || 1).to_i
        per_page = [(params[:per_page].presence || 8).to_i, 100].min
        paginated = transactions.page(page).per(per_page)

        render_success(
          message: "Financial transactions retrieved successfully",
          data: FinancialTransactionPresenter.collection(paginated),
          meta: pagination_meta(paginated).merge(summary: summary),
        )
      end

      def dashboard
        transactions = apply_filters(base_scope)
        summary = build_summary(transactions)

        render_success(
          message: "Financial dashboard retrieved successfully",
          data: {
            summary: summary,
            charts: {
              monthly_revenue_vs_expense:
                monthly_revenue_vs_expense(transactions),
              revenue_breakdown_by_category:
                revenue_breakdown_by_category(transactions),
            },
          },
        )
      end

      def show
        render_success(
          message: "Financial transaction retrieved successfully",
          data: FinancialTransactionPresenter.as_json(@transaction),
        )
      end

      def create
        transaction = FinancialTransaction.new(
          create_params.merge(created_by: current_user),
        )
        attach_receipt(transaction)

        unless transaction.save
          return render_error(
            message: "Validation failed",
            errors: transaction.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "create",
          module_name: "Financial",
          description: "Created financial transaction ##{transaction.id}",
        )

        render_success(
          message: "Financial transaction created successfully",
          data: FinancialTransactionPresenter.as_json(transaction),
          status: :created,
        )
      end

      def update
        @transaction.assign_attributes(update_params)
        attach_receipt(@transaction)

        unless @transaction.save
          return render_error(
            message: "Validation failed",
            errors: @transaction.errors.full_messages,
            status: :unprocessable_entity,
          )
        end

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "update",
          module_name: "Financial",
          description: "Updated financial transaction ##{@transaction.id}",
        )

        render_success(
          message: "Financial transaction updated successfully",
          data: FinancialTransactionPresenter.as_json(@transaction),
        )
      end

      def destroy
        id = @transaction.id
        @transaction.destroy!

        LogActivities::LogActivityService.log(
          admin: current_user,
          action: "delete",
          module_name: "Financial",
          description: "Deleted financial transaction ##{id}",
        )

        render_success(message: "Financial transaction deleted successfully")
      end

      def export
        transactions = apply_sort(apply_filters(base_scope))

        send_data(
          build_excel_data(transactions),
          filename: "financial-transactions.xls",
          type: "application/vnd.ms-excel",
        )
      end

      private

      def ensure_admin!
        return if current_user&.admin?

        render_error(
          message: "Forbidden",
          errors: ["Only admin can manage financial transactions"],
          status: :forbidden,
        )
      end

      def base_scope
        FinancialTransaction.includes(
          :property,
          :unit,
          :created_by,
          receipt_attachment: :blob,
        )
      end

      def set_transaction
        @transaction = base_scope.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error(
          message: "Financial transaction not found",
          errors: ["Financial transaction not found"],
          status: :not_found,
        )
      end

      def create_params
        financial_transaction_params.except(:receipt)
      end

      def update_params
        financial_transaction_params.except(:receipt)
      end

      def financial_transaction_params
        params.require(:financial_transaction).permit(
          :property_id,
          :unit_id,
          :category,
          :transaction_date,
          :amount,
          :description,
          :notes,
          :receipt,
        )
      end

      def attach_receipt(transaction)
        receipt = financial_transaction_params[:receipt]
        return unless receipt.present?

        transaction.receipt.attach(receipt)
      end

      def apply_filters(scope, include_category: true)
        filtered = scope

        if params[:property_id].present?
          filtered = filtered.where(property_id: params[:property_id])
        end

        if params[:unit_id].present?
          filtered = filtered.where(unit_id: params[:unit_id])
        end

        if include_category && params[:category].present?
          filtered = filtered.where(category: params[:category])
        end

        filtered = apply_period_filter(filtered)

        if params[:date_from].present?
          filtered = filtered.where("transaction_date >= ?", params[:date_from])
        end

        if params[:date_to].present?
          filtered = filtered.where("transaction_date <= ?", params[:date_to])
        end

        if params[:search].present?
          term = "%#{params[:search]}%"
          filtered = filtered.left_joins(:property, :unit).where(
            "financial_transactions.description ILIKE :term OR " \
            "properties.name ILIKE :term OR units.name ILIKE :term",
            term: term,
          ).distinct
        end

        filtered
      end

      def apply_period_filter(scope)
        case params[:period]
        when "this_week"
          scope.this_week
        when "this_month"
          scope.this_month
        when "last_month"
          scope.last_month
        else
          scope
        end
      end

      def apply_sort(scope)
        case params[:sort]
        when "oldest"
          scope.order(transaction_date: :asc, created_at: :asc)
        when "amount_asc"
          scope.order(amount: :asc)
        when "amount_desc"
          scope.order(amount: :desc)
        else
          scope.order(transaction_date: :desc, created_at: :desc)
        end
      end

      def build_excel_data(transactions)
        rows = [build_excel_row(excel_headers)]
        rows.concat(
          transactions.map { |item| build_excel_row(excel_values(item)) },
        )

        <<~XML
          <?xml version="1.0"?>
          <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
            xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
            <Worksheet ss:Name="Financial Transactions">
              <Table>
                #{rows.join}
              </Table>
            </Worksheet>
          </Workbook>
        XML
      end

      def excel_headers
        [
          "Date",
          "Property",
          "Unit",
          "Category",
          "Amount",
          "Description",
          "Created By",
        ]
      end

      def excel_values(transaction)
        [
          transaction.transaction_date,
          transaction.property&.name,
          transaction.unit&.name,
          transaction.category,
          transaction.amount,
          transaction.description,
          transaction.created_by&.full_name,
        ]
      end

      def build_excel_row(values)
        cells = values.map do |value|
          "<Cell><Data ss:Type=\"String\">#{escape_xml(value)}</Data></Cell>"
        end

        "<Row>#{cells.join}</Row>"
      end

      def escape_xml(value)
        CGI.escapeHTML(value.to_s)
      end

      def build_summary(scope)
        revenue = scope.income.sum(:amount).to_f
        expenses = scope.expense.sum(:amount).to_f

        {
          total_revenue: revenue,
          total_expenses: expenses,
          net_operating_income: revenue - expenses,
          outstanding_balances: outstanding_balances_total,
        }
      end

      def outstanding_balances_total
        scope = apply_filters(base_scope, include_category: false).expense
        scope.where(
          "financial_transactions.description ILIKE :keyword OR " \
          "COALESCE(financial_transactions.notes, '') ILIKE :keyword",
          keyword: "%outstanding%",
        ).sum(:amount).to_f
      end

      def monthly_revenue_vs_expense(scope)
        range = chart_date_range
        month_start = range[:from].beginning_of_month
        month_end = range[:to].beginning_of_month
        sums_by_month = revenue_expense_sums_by_month(scope, range)

        months = []
        current_month = month_start
        while current_month <= month_end
          month_key = current_month.strftime("%Y-%m")
          month_values = sums_by_month.fetch(month_key, {})

          months << {
            month: current_month.strftime("%b"),
            revenue: month_values.fetch("income", 0.0),
            expense: month_values.fetch("expense", 0.0),
          }
          current_month = current_month.next_month
        end

        months
      end

      def revenue_expense_sums_by_month(scope, range)
        scope.where(transaction_date: range[:from]..range[:to]).group(
          "DATE_TRUNC('month', transaction_date)",
          :category,
        ).sum(:amount).each_with_object({}) do |((month, category), amount), memo|
          month_key = month.to_date.strftime("%Y-%m")
          memo[month_key] ||= {}
          memo[month_key][category] = amount.to_f
        end
      end

      def revenue_breakdown_by_category(scope)
        grouped = scope.income.group(:description).sum(:amount)
        total = grouped.values.sum.to_f
        return [] if total.zero?

        grouped.sort_by { |_, amount| -amount }.first(6).map do |label, amount|
          value = amount.to_f
          {
            category: label.presence || "Uncategorized",
            amount: value,
            percentage: ((value / total) * 100).round(2),
          }
        end
      end

      def chart_date_range
        from = extract_date(params[:date_from])
        to = extract_date(params[:date_to])

        if from.present? && to.present?
          return { from: from, to: to }
        end

        case params[:period]
        when "this_week"
          {
            from: Date.current.beginning_of_week,
            to: Date.current.end_of_week,
          }
        when "this_month"
          {
            from: Date.current.beginning_of_month,
            to: Date.current.end_of_month,
          }
        when "last_month"
          date = Date.current.last_month
          {
            from: date.beginning_of_month,
            to: date.end_of_month,
          }
        else
          {
            from: Date.current.beginning_of_year,
            to: Date.current.end_of_year,
          }
        end
      end

      def extract_date(value)
        return nil if value.blank?

        Date.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
