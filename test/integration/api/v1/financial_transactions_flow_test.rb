# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class FinancialTransactionsFlowTest < ActionDispatch::IntegrationTest
      setup do
        [
          CommunicationRecipient,
          Communication,
          Payment,
          MaintenanceRequest,
          Lease,
          Unit,
          FinancialTransaction,
          Property,
          LogActivity,
          RevokedToken,
          User,
        ].each(&:delete_all)

        @admin = User.create!(
          full_name: "Admin Test",
          email: "admin.finance@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )
        @owner = User.create!(
          full_name: "Owner Test",
          email: "owner.finance@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )

        @property = Property.create!(
          user: @owner,
          name: "Property Finance Test",
          address: "Jl. Finansial No. 1",
          property_type: "kost",
          condition: "good",
          facilities: ["wifi"],
          rules: "No smoking",
          description: "Property untuk test financial transaction",
        )

        @income = FinancialTransaction.create!(
          property: @property,
          created_by: @admin,
          category: :income,
          transaction_date: Date.current,
          amount: 3_500_000,
          description: "Income transaction sample",
          notes: "Transfer bank",
        )
        @expense = FinancialTransaction.create!(
          property: @property,
          created_by: @admin,
          category: :expense,
          transaction_date: Date.current - 1.day,
          amount: 500_000,
          description: "Expense transaction sample",
          notes: "Biaya maintenance",
        )
        @unit = Unit.create!(
          property: @property,
          name: "Unit 101",
          unit_type: "standard",
          status: :vacant,
          people_allowed: 1,
          price: 2_000_000,
        )
        FinancialTransaction.create!(
          property: @property,
          created_by: @admin,
          category: :expense,
          transaction_date: Date.current,
          amount: 1_500_000,
          description: "Outstanding rent",
          notes: "manual outstanding",
        )
      end

      test "admin can filter financial transactions" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/financial_transactions",
          params: {
            category: "income",
            property_id: @property.id,
            date_from: Date.current.to_s,
            date_to: Date.current.to_s,
            search: "Property Finance Test",
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? { |item| item["category"] == "income" })
        assert(body["data"].all? { |item| item["property_label"].present? })
        assert_equal 3_500_000.0, body.dig("meta", "summary", "total_revenue")
        assert_equal 1_500_000.0, body.dig("meta", "summary", "total_expenses")
        assert_equal 2_000_000.0,
                     body.dig("meta", "summary", "net_operating_income")
        assert_equal 1_500_000.0,
                     body.dig("meta", "summary", "outstanding_balances")
      end

      test "admin can view financial dashboard charts" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/financial_transactions/dashboard",
          params: {
            period: "this_month",
            property_id: @property.id,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_includes body["data"].keys, "summary"
        assert_includes body["data"].keys, "charts"
        assert_not_empty body.dig("data", "charts", "monthly_revenue_vs_expense")
        breakdown = body.dig("data", "charts", "revenue_breakdown_by_category")
        assert_not_empty breakdown
      end

      test "non admin cannot create financial transaction" do
        token = login_token(@owner.email, "Password123!")

        post(
          "/api/v1/financial_transactions",
          params: {
            financial_transaction: {
              property_id: @property.id,
              category: "income",
              transaction_date: Date.current.to_s,
              amount: 1_000_000,
              description: "Forbidden create test",
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

        assert_response :forbidden
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
      end

      test "admin can export financial transactions to excel" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/financial_transactions/export",
          headers: auth_headers(token),
        )

        assert_response :success
        assert_includes(
          response.headers["Content-Type"],
          "application/vnd.ms-excel",
        )
        assert_includes response.body, "<Workbook"
        assert_includes response.body, "Financial Transactions"
      end

      private

      def login_token(email, password)
        post(
          "/api/v1/auth/login",
          params: {
            email: email,
            password: password,
          },
          as: :json,
        )

        assert_response :success
        JSON.parse(response.body).dig("data", "token")
      end

      def auth_headers(token)
        {
          "Authorization" => "Bearer #{token}",
        }
      end
    end
  end
end
