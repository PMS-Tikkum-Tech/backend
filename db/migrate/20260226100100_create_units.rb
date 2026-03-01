# frozen_string_literal: true

class CreateUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :units do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false
      t.string :unit_type, null: false
      t.integer :status, null: false, default: 0
      t.integer :people_allowed, null: false, default: 1
      t.decimal :price, precision: 14, scale: 2, null: false

      t.timestamps
    end

    add_index :units, :status
    add_index :units, :unit_type
    add_index :units, :name
  end
end
