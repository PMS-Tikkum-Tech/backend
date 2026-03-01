# frozen_string_literal: true

class CreateCommunications < ActiveRecord::Migration[6.1]
  def change
    create_table :communications do |t|
      t.references :property, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :audience_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :subject, null: false
      t.text :message, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at

      t.timestamps
    end

    add_index :communications, :audience_type
    add_index :communications, :status
    add_index :communications, :scheduled_at
  end
end
