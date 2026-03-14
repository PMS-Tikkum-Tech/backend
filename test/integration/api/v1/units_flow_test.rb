# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class UnitsFlowTest < ActionDispatch::IntegrationTest
      setup do
        [
          Lease,
          Unit,
          Property,
          LogActivity,
          RevokedToken,
          User,
        ].each(&:delete_all)

        @admin = User.create!(
          full_name: "Admin Unit",
          email: "admin.unit@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )
        @owner_1 = User.create!(
          full_name: "Owner Satu",
          email: "owner.satu.unit@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )
        @owner_2 = User.create!(
          full_name: "Owner Dua",
          email: "owner.dua.unit@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )

        @property_owner_1 = Property.create!(
          user: @owner_1,
          name: "Kinara Owner One",
          address: "Jl. Owner One",
          property_type: "kost",
          condition: "good",
          facilities: ["wifi"],
          rules: "No smoking",
          description: "Property owner one",
        )
        @property_owner_2 = Property.create!(
          user: @owner_2,
          name: "Kinara Owner Two",
          address: "Jl. Owner Two",
          property_type: "apartment",
          condition: "good",
          facilities: ["wifi"],
          rules: "No loud noise",
          description: "Property owner two",
        )

        Unit.create!(
          property: @property_owner_1,
          name: "Unit Owner One A",
          unit_type: "standard",
          status: :vacant,
          people_allowed: 2,
          price: 2_500_000,
        )
        Unit.create!(
          property: @property_owner_1,
          name: "Unit Owner One B",
          unit_type: "deluxe",
          status: :occupied,
          people_allowed: 2,
          price: 3_000_000,
        )
        Unit.create!(
          property: @property_owner_2,
          name: "Unit Owner Two A",
          unit_type: "premium",
          status: :vacant,
          people_allowed: 3,
          price: 4_000_000,
        )
      end

      test "admin can list units by owner id" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/units/owner/#{@owner_1.id}",
          params: {
            page: 1,
            per_page: 5,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)

        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? do |item|
          item.dig("property", "id") == @property_owner_1.id
        end)
      end

      test "non admin cannot list units by owner id" do
        token = login_token(@owner_1.email, "Password123!")

        get(
          "/api/v1/units/owner/#{@owner_1.id}",
          headers: auth_headers(token),
        )

        assert_response :forbidden
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
      end

      test "owner id must exist and have owner role" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/units/owner/999999",
          headers: auth_headers(token),
        )

        assert_response :not_found
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
        assert_equal "Owner not found", body["message"]
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
