# frozen_string_literal: true

class AddUserEmergencyFields < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :emergency_contact_name, :string
    add_column :users, :emergency_contact_number, :bigint
    add_column :users, :relationship, :string
    add_column :users, :nik, :bigint
  end
end
