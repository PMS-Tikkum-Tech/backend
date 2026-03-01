# frozen_string_literal: true

class Communication < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :created_by,
             class_name: "User",
             inverse_of: :communications_created

  has_many :communication_recipients, dependent: :destroy
  has_many :tenants, through: :communication_recipients, source: :tenant

  enum audience_type: {
    all_tenants: 0,
    some_tenants: 1,
    specific_tenants: 2
  }

  enum status: {
    scheduled: 0,
    sent: 1,
    failed: 2
  }

  validates :subject, presence: true
  validates :message, presence: true
  validates :scheduled_at, presence: true

  after_commit :schedule_delivery, on: :create

  def delivery_due?
    scheduled_at <= Time.current
  end

  private

  def schedule_delivery
    if delivery_due?
      SendCommunicationJob.perform_later(id)
    else
      SendCommunicationJob.set(wait_until: scheduled_at).perform_later(id)
    end
  end
end
