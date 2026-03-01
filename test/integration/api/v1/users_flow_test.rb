# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class UsersFlowTest < ActionDispatch::IntegrationTest
      setup do
        User.delete_all
        RevokedToken.delete_all
        LogActivity.delete_all

        @admin = User.create!(
          full_name: "Admin Test",
          email: "admin.test@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )

        @owner = User.create!(
          full_name: "Owner Test",
          email: "owner.test@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )

        @tenant = User.create!(
          full_name: "Tenant Test",
          email: "tenant.test@kyrastay.local",
          password: "Password123!",
          role: :tenant,
          account_status: :active,
        )
      end

      test "admin can create user without profile picture" do
        token = login_token(@admin.email, "Password123!")

        post(
          "/api/v1/users",
          params: {
            user: {
              full_name: "Tenant Baru Test",
              email: "tenant.baru.test@kyrastay.local",
              password: "Password123!",
              role: "tenant",
              account_status: "active",
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

        assert_response :created
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "tenant", body.dig("data", "role")
        assert_nil body.dig("data", "profile_picture_url")
      end

      test "admin can create user with emergency and nik fields" do
        token = login_token(@admin.email, "Password123!")

        post(
          "/api/v1/users",
          params: {
            user: {
              full_name: "Tenant Field Test",
              email: "tenant.field.test@kyrastay.local",
              password: "Password123!",
              role: "tenant",
              emergency_contact_name: "Ahmad",
              emergency_contact_number: 81234567890,
              relationship: "father",
              nik: 32_011_906_030_003,
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

        assert_response :created
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "Ahmad", body.dig("data", "emergency_contact_name")
        assert_equal 81_234_567_890, body.dig("data", "emergency_contact_number")
        assert_equal "father", body.dig("data", "relationship")
        assert_equal 32_011_906_030_003, body.dig("data", "nik")
      end

      test "non admin cannot create user" do
        token = login_token(@owner.email, "Password123!")

        post(
          "/api/v1/users",
          params: {
            user: {
              full_name: "Should Fail",
              email: "should.fail@kyrastay.local",
              password: "Password123!",
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

        assert_response :forbidden
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
      end

      test "admin can list users by role endpoint" do
        token = login_token(@admin.email, "Password123!")

        assert_role_endpoint(token, "/api/v1/users/tenant?page=1&per_page=10",
                             "tenant")
        assert_role_endpoint(token, "/api/v1/users/admin?page=1&per_page=10",
                             "admin")
        assert_role_endpoint(token, "/api/v1/users/owner?page=1&per_page=10",
                             "owner")
      end

      private

      def assert_role_endpoint(token, path, expected_role)
        get(path, headers: auth_headers(token))

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? { |user| user["role"] == expected_role })
      end

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
        body = JSON.parse(response.body)
        body.dig("data", "token")
      end

      def auth_headers(token)
        {
          "Authorization" => "Bearer #{token}",
        }
      end
    end
  end
end
