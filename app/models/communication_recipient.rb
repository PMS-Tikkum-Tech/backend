# frozen_string_literal: true

class CommunicationRecipient < ApplicationRecord
  belongs_to :communication
  belongs_to :tenant,
             class_name: "User",
             inverse_of: :communication_recipients_as_tenant

  enum status: {
    scheduled: 0,
    sent: 1,
    failed: 2,
  }

  validates :tenant_id, uniqueness: { scope: :communication_id }
end
