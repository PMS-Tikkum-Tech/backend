# frozen_string_literal: true

class Lease < ApplicationRecord
  belongs_to :unit
  belongs_to :tenant,
             class_name: "User",
             inverse_of: :leases_as_tenant

  has_one :property, through: :unit
  has_many :payments, dependent: :nullify

  enum lease_status: {
    active: 0,
    ended: 1,
    cancelled: 2,
  }

  enum payment_status: {
    paid: 0,
    unpaid: 1,
  }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :active, -> { where(lease_status: lease_statuses[:active]) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be greater than or equal to start date")
  end
end
