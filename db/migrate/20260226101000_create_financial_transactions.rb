# frozen_string_literal: true

class CreateFinancialTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :financial_transactions do |t|
      t.references :property, null: false, foreign_key: true
      t.references :unit, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :category, null: false, default: 0
      t.date :transaction_date, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.text :description, null: false
      t.text :notes

      t.timestamps
    end

    add_index :financial_transactions, :category
    add_index :financial_transactions, :transaction_date
    add_index :financial_transactions, [:property_id, :transaction_date],
              name: "idx_financial_transactions_property_date"
  end
end
