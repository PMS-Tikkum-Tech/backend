# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :property
  belongs_to :unit
  belongs_to :tenant,
             class_name: "User",
             inverse_of: :payments_as_tenant
  belongs_to :lease, optional: true

  enum status: {
    waiting: 0,
    paid: 1,
    overdue: 2,
    cancelled: 3,
  }

  before_validation :generate_invoice_id, on: :create
  after_commit :sync_lease_payment_status, if: :saved_change_to_status?

  validates :amount, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :invoice_id, presence: true, uniqueness: true

  scope :by_property, ->(property_id) { where(property_id: property_id) }
  scope :by_status, ->(status) { where(status: status) }

  def push_to_xendit
    response = Xendit::InvoiceService.new.create_invoice(self)
    return response unless response[:success]

    update!(xendit_invoice_id: response.dig(:data, "id"))
    response
  end

  def check_overdue!
    return unless waiting?
    return unless Date.current > due_date

    update!(status: :overdue)
  end

  private

  def generate_invoice_id
    return if invoice_id.present?

    token = SecureRandom.hex(3).upcase
    self.invoice_id = "INV-#{Time.current.strftime('%Y%m%d%H%M%S')}-#{token}"
  end

  def sync_lease_payment_status
    return unless lease

    if paid?
      lease.update!(payment_status: :paid)
    elsif waiting? || overdue? || cancelled?
      lease.update!(payment_status: :unpaid)
    end
  end
end
