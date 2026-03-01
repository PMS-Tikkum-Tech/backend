# frozen_string_literal: true

require "csv"

module Properties
  class ExportService
    def self.tenants_csv(rows)
      CSV.generate(headers: true) do |csv|
        csv << ["Tenant Name", "Unit ID", "Unit Name", "Phone", "Lease End", "Status"]
        rows.each do |row|
          csv << [
            row[:tenant_name],
            row[:unit_id],
            row[:unit_name],
            row[:mobile_phone],
            row[:lease_end],
            row[:payment_status],
          ]
        end
      end
    end

    def self.units_csv(rows)
      CSV.generate(headers: true) do |csv|
        csv << ["Unit ID", "Unit Name", "Unit Type", "Tenant", "Price", "Lease End", "Status"]
        rows.each do |row|
          csv << [
            row[:unit_id],
            row[:unit_name],
            row[:unit_type],
            row[:tenant_name],
            row[:price],
            row[:lease_end],
            row[:status],
          ]
        end
      end
    end

    def self.maintenance_csv(rows)
      CSV.generate(headers: true) do |csv|
        csv << ["Date", "Unit", "Tenant", "Issue", "Category", "Priority", "Status"]
        rows.each do |row|
          csv << [
            row[:date],
            row[:unit_name],
            row[:tenant_name],
            row[:issue],
            row[:category],
            row[:priority],
            row[:status],
          ]
        end
      end
    end
  end
end
