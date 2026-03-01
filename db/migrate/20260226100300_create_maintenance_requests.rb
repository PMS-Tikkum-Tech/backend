# frozen_string_literal: true

class CreateMaintenanceRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :maintenance_requests do |t|
      t.references :property, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.string :issue, null: false
      t.string :category, null: false
      t.text :description
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.date :requested_date
      t.date :repair_date
      t.string :visiting_hours

      t.timestamps
    end

    add_index :maintenance_requests, :priority
    add_index :maintenance_requests, :status
    add_index :maintenance_requests, :category
    add_index :maintenance_requests, :requested_date
  end
end
