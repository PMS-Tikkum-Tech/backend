# frozen_string_literal: true

class FinancialTransactionPresenter
  def self.collection(transactions)
    transactions.map { |transaction| as_json(transaction) }
  end

  def self.as_json(transaction)
    {
      transaction_date: transaction.transaction_date,
      id: transaction.id,
      property: {
        id: transaction.property_id,
        name: transaction.property&.name,
      },
      unit: {
        id: transaction.unit_id,
        name: transaction.unit&.name,
      },
      description: transaction.description,
      amount: transaction.amount.to_f,
      category: transaction.category,
      receipt_url: receipt_url(transaction),
      property_label: property_label(transaction),
      notes: transaction.notes,
      created_by: {
        id: transaction.created_by_id,
        full_name: transaction.created_by&.full_name,
      },
      created_at: transaction.created_at&.iso8601,
      updated_at: transaction.updated_at&.iso8601,
    }
  end

  def self.receipt_url(transaction)
    return nil unless transaction.receipt.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      transaction.receipt,
      only_path: true,
    )
  end

  def self.property_label(transaction)
    [transaction.property&.name, transaction.unit&.name].compact.join(", ")
  end
end
