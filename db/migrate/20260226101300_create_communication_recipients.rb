# frozen_string_literal: true

class CreateCommunicationRecipients < ActiveRecord::Migration[6.1]
  def change
    create_table :communication_recipients do |t|
      t.references :communication, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :sent_at
      t.text :failed_reason

      t.timestamps
    end

    add_index :communication_recipients,
              [:communication_id, :tenant_id],
              unique: true,
              name: "idx_communication_recipients_unique"
    add_index :communication_recipients, :status
  end
end
