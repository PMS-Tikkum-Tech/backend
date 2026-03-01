# frozen_string_literal: true

class CreateLeases < ActiveRecord::Migration[6.1]
  def change
    create_table :leases do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :lease_status, null: false, default: 0
      t.integer :payment_status, null: false, default: 1

      t.timestamps
    end

    add_index :leases, :lease_status
    add_index :leases, :payment_status
    add_index :leases, [:tenant_id, :lease_status]
  end
end
