# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[6.1]
  def change
    create_table :payments do |t|
      t.references :property, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.references :lease, foreign_key: true
      t.string :invoice_id, null: false
      t.string :xendit_invoice_id
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.date :due_date, null: false
      t.datetime :paid_at
      t.string :payment_method
      t.text :description

      t.timestamps
    end

    add_index :payments, :invoice_id, unique: true
    add_index :payments, :xendit_invoice_id, unique: true
    add_index :payments, :status
    add_index :payments, :due_date
    add_index :payments, [:property_id, :status], name: "idx_payments_property_status"
  end
end
