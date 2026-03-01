# frozen_string_literal: true

class FinancialTransaction < ApplicationRecord
  belongs_to :property
  belongs_to :unit, optional: true
  belongs_to :created_by,
             class_name: "User",
             inverse_of: :financial_transactions_created

  has_one_attached :receipt

  enum category: {
    income: 0,
    expense: 1,
  }

  validates :transaction_date, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :description, presence: true, length: { minimum: 10 }
  validate :receipt_format

  scope :this_week, lambda {
    where(transaction_date: Date.current.beginning_of_week..Date.current.end_of_week)
  }
  scope :this_month, lambda {
    where(transaction_date: Date.current.beginning_of_month..
      Date.current.end_of_month)
  }
  scope :last_month, lambda {
    date = Date.current.last_month
    where(transaction_date: date.beginning_of_month..date.end_of_month)
  }

  private

  def receipt_format
    return unless receipt.attached?

    allowed_types = [
      "application/pdf",
      "image/jpeg",
      "image/jpg",
      "image/png",
    ]

    return if allowed_types.include?(receipt.content_type)

    errors.add(:receipt, "must be PDF, PNG, JPG, or JPEG")
  end
end
