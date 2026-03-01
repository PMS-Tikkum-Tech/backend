# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class CommunicationsFlowTest < ActionDispatch::IntegrationTest
      setup do
        [
          CommunicationRecipient,
          Communication,
          Lease,
          Unit,
          Property,
          LogActivity,
          RevokedToken,
          User,
        ].each(&:delete_all)

        @admin = User.create!(
          full_name: "Admin Communication",
          email: "admin.communication@kyrastay.local",
          password: "Password123!",
          role: :admin,
          account_status: :active,
        )
        @owner = User.create!(
          full_name: "Owner Communication",
          email: "owner.communication@kyrastay.local",
          password: "Password123!",
          role: :owner,
          account_status: :active,
        )
        @tenant_1 = User.create!(
          full_name: "Tenant One",
          email: "tenant.one.communication@kyrastay.local",
          password: "Password123!",
          role: :tenant,
          account_status: :active,
        )
        @tenant_2 = User.create!(
          full_name: "Tenant Two",
          email: "tenant.two.communication@kyrastay.local",
          password: "Password123!",
          role: :tenant,
          account_status: :active,
        )

        @property_kost = Property.create!(
          user: @owner,
          name: "Kinara Signature Kost",
          address: "Jl. Merdeka No. 10",
          property_type: "kost",
          condition: "good",
          facilities: ["wifi"],
          rules: "No smoking",
          description: "Property komunikasi kost",
        )
        @property_apartment = Property.create!(
          user: @owner,
          name: "Sunset Apts",
          address: "Jl. Sunset No. 2",
          property_type: "apartment",
          condition: "good",
          facilities: ["wifi"],
          rules: "No loud noise",
          description: "Property komunikasi apartment",
        )

        @communication_1 = Communication.new(
          property: @property_kost,
          created_by: @admin,
          audience_type: :some_tenants,
          status: :sent,
          subject: "Perbaikan Pipa Air Utama",
          message: "Perbaikan pipa akan dilakukan pukul 09:00",
          scheduled_at: Time.current,
        )
        @communication_1.communication_recipients.build(
          tenant: @tenant_1,
          status: :sent,
          sent_at: Time.current,
        )
        @communication_1.save!

        @communication_2 = Communication.new(
          property: @property_apartment,
          created_by: @admin,
          audience_type: :all_tenants,
          status: :scheduled,
          subject: "Ucapan Selamat Natal",
          message: "Selamat hari natal untuk semua tenant",
          scheduled_at: 1.day.from_now,
        )
        @communication_2.communication_recipients.build(
          tenant: @tenant_2,
          status: :scheduled,
        )
        @communication_2.save!
      end

      test "admin can list communications with property filter and search" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/communications",
          params: {
            property_type: "kost",
            search: "Kinara Signature",
            sort: "newest",
            page: 1,
            per_page: 10,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? do |item|
          item["target_property"] == "Kinara Signature Kost"
        end)
        assert(body["data"].all? { |item| item["audience_label"].present? })
      end

      test "admin can filter by propertyType with ui label format" do
        token = login_token(@admin.email, "Password123!")

        get(
          "/api/v1/communications",
          params: {
            propertyType: "Apartment",
            page: 1,
            per_page: 10,
          },
          headers: auth_headers(token),
        )

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_not_empty body["data"]
        assert(body["data"].all? do |item|
          item.dig("property", "property_type") == "apartment"
        end)
      end

      test "admin can create communication with send_now mode" do
        token = login_token(@admin.email, "Password123!")

        post(
          "/api/v1/communications",
          params: {
            communication: {
              property_id: @property_kost.id,
              audience_type: "some_tenants",
              subject: "Reminder Pembayaran",
              message: "Harap lakukan pembayaran sewa minggu ini.",
              send_schedule: "send_now",
              tenant_ids: [@tenant_1.id, @tenant_2.id],
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

        assert_response :created
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "Kinara Signature Kost", body.dig("data", "target_property")
        assert_not_nil body.dig("data", "scheduled_at")
      end

      test "non admin cannot create communication" do
        token = login_token(@owner.email, "Password123!")

        post(
          "/api/v1/communications",
          params: {
            communication: {
              property_id: @property_kost.id,
              audience_type: "some_tenants",
              subject: "Forbidden",
              message: "Should fail for non admin",
              send_schedule: "send_now",
              tenant_ids: [@tenant_1.id],
            },
          },
          headers: auth_headers(token),
          as: :json,
        )

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
