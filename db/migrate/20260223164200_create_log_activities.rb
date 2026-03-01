# frozen_string_literal: true

class CreateLogActivities < ActiveRecord::Migration[6.1]
  def change
    create_table :log_activities do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :module_name, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :log_activities, :module_name
    add_index :log_activities, :action
    add_index :log_activities, :created_at
  end
end
