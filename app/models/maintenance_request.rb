# frozen_string_literal: true

class MaintenanceRequest < ApplicationRecord
  CATEGORIES = [
    "plumbing",
    "electrical",
    "appliance",
    "cleaning",
    "pest_control",
    "hvac",
    "carpentry",
    "general",
  ].freeze

  belongs_to :property
  belongs_to :unit
  belongs_to :tenant,
             class_name: "User",
             inverse_of: :maintenance_requests_as_tenant
  belongs_to :assigned_to,
             class_name: "User",
             optional: true,
             inverse_of: :maintenance_requests_as_technician

  enum priority: {
    high: 0,
    medium: 1,
    low: 2,
  }

  enum status: {
    unassigned: 0,
    assigned: 1,
    pending_vendor: 2,
    in_progress: 3,
    completed: 4,
    cancelled: 5,
  }

  before_validation :set_default_requested_date
  after_create :prepare_whatsapp_notification

  validates :issue, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  private

  def set_default_requested_date
    self.requested_date ||= Date.current
  end

  def prepare_whatsapp_notification
    tenant_phone = tenant&.phone_number.presence || "-"
    Rails.logger.info(
      "Prepared WhatsApp maintenance notification for tenant: #{tenant_phone}",
    )
  end
end
