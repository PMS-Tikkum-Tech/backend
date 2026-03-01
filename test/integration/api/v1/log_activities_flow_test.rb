# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class LogActivitiesFlowTest < ActionDispatch::IntegrationTest
      setup do
        [
          LogActivity,
          RevokedToken,
          User,
        ].each(&:delete_all)

        @admin_1 = User.create!(
          full_name: "Admin Utama",
          email: "admin.utama.log@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )
        @admin_2 = User.create!(
          full_name: "Admin Dua",
          email: "admin.dua.log@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )
        @owner = User.create!(
          full_name: "Owner Log",
          email: "owner.log@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )

        LogActivity.create!(
          admin: @admin_1,
          action: "update",
          module_name: "Maintenance",
          description: "Mengubah teknisi pada tiket #102",
        )
        LogActivity.create!(
          admin: @admin_2,
          action: "delete",
          module_name: "Financial",
          description: "Menghapus transaksi pembayaran unit 4B",
        )
        LogActivity.create!(
          admin: @admin_1,
          action: "create",
          module_name: "Communication",
          description: "Mengirim pengumuman pemadaman",
        )
        @english_log = LogActivity.create!(
          admin: @admin_1,
          action: "delete",
          module_name: "Communication",
          description: "Deleted communication #34",
        )
      end

      test "admin can list log activities with ui fields and meta" do
        token = login_token(@admin_1.email, "Password123!")

        get(
          "/api/v1/log_activities",
          params: {
            page: 1,
            per_page: 12,
            sort: "newest",
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)

        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert_equal 1, body.dig("meta", "current_page")
        assert_equal 12, body.dig("meta", "per_page")
        assert_equal 1, body.dig("meta", "showing_from")
        assert_equal 4, body.dig("meta", "showing_to")

        first_row = body["data"].first
        assert_not_nil first_row["timestamp"]
        assert_not_nil first_row["admin_name"]
        assert_not_nil first_row["module_page"]
        assert_not_nil first_row["action_label"]
        assert_not_nil first_row["description"]
        assert_nil first_row["description_raw"]
      end

      test "list uses concise description" do
        token = login_token(@admin_1.email, "Password123!")

        get(
          "/api/v1/log_activities",
          params: {
            search: "Deleted communication #34",
            page: 1,
            per_page: 12,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_not_empty body["data"]

        row = body["data"].find { |item| item["id"] == @english_log.id }
        assert_not_nil row
        assert_equal "Menghapus komunikasi", row["description"]
      end

      test "show returns detailed and raw description" do
        token = login_token(@admin_1.email, "Password123!")

        get(
          "/api/v1/log_activities/#{@english_log.id}",
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal @english_log.id, body.dig("data", "id")
        assert_equal "Menghapus komunikasi", body.dig("data", "description")
        assert_equal(
          "Menghapus komunikasi #34",
          body.dig("data", "description_detail"),
        )
        assert_equal(
          "Deleted communication #34",
          body.dig("data", "description_raw"),
        )
      end

      test "admin can filter by module_page alias and admin_name" do
        token = login_token(@admin_1.email, "Password123!")

        get(
          "/api/v1/log_activities",
          params: {
            module_page: "Transaction",
            admin_name: "Admin Dua",
            page: 1,
            per_page: 12,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)

        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? do |item|
          item["module_name"] == "Financial"
        end)
        assert(body["data"].all? do |item|
          item["admin_name"] == "Admin Dua"
        end)
      end

      test "non admin cannot access log activities" do
        token = login_token(@owner.email, "Password123!")

        get("/api/v1/log_activities", headers: auth_headers(token))

        assert_response :forbidden
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
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
