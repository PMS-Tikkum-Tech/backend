# frozen_string_literal: true

module Xendit
  class InvoiceService
    def create_invoice(payment)
      {
        success: true,
        data: {
          "id" => "xnd-#{payment.invoice_id}",
          "external_id" => payment.invoice_id,
        },
      }
    end
  end
end
