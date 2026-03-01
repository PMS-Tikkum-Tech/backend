# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone_number
      # 0 = owner, 1 = admin, 2 = tenant
      t.integer :role, null: false, default: 2
      t.integer :account_status, null: false, default: 0
      t.string :refresh_token
      t.datetime :refresh_token_expires_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :account_status
    add_index :users, :refresh_token, unique: true
  end
end
