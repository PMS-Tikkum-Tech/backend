# frozen_string_literal: true

class PaymentPresenter
  def self.collection(payments)
    payments.map { |payment| as_json(payment) }
  end

  def self.as_json(payment)
    {
      id: payment.id,
      invoice_id: payment.invoice_id,
      xendit_invoice_id: payment.xendit_invoice_id,
      property: {
        id: payment.property_id,
        name: payment.property&.name,
      },
      unit: {
        id: payment.unit_id,
        name: payment.unit&.name,
      },
      tenant: {
        id: payment.tenant_id,
        full_name: payment.tenant&.full_name,
      },
      lease_id: payment.lease_id,
      status: payment.status,
      amount: payment.amount.to_f,
      due_date: payment.due_date,
      paid_at: payment.paid_at&.iso8601,
      payment_method: payment.payment_method,
      description: payment.description,
      created_at: payment.created_at&.iso8601,
      updated_at: payment.updated_at&.iso8601,
    }
  end
end
