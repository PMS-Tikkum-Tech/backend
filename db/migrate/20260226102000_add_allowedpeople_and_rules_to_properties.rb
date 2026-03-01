# frozen_string_literal: true

class AddAllowedpeopleAndRulesToProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :properties, :allowedpeople, :integer, null: false, default: 1
    add_column :properties, :rules, :text, null: false, default: ""
    add_index :properties, :allowedpeople
  end
end
