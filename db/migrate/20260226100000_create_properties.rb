# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[6.1]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.text :address, null: false
      t.string :property_type, null: false
      t.string :condition, null: false
      t.jsonb :facilities, null: false, default: []

      t.timestamps
    end

    add_index :properties, :property_type
    add_index :properties, :condition
    add_index :properties, :name
  end
end
