# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      module Xendit
        class InvoicesController < ApplicationController
          include BaseController

          def paid
            payment = Payment.find_by(xendit_invoice_id: params[:id])

            if payment && params[:status].to_s.upcase == "PAID"
              payment.update!(
                status: :paid,
                paid_at: Time.current,
                payment_method: params[:payment_method],
              )
            end

            render json: { success: true }
          rescue StandardError => exception
            render_error(
              message: "Webhook processing failed",
              errors: [exception.message],
              status: :unprocessable_entity,
            )
          end
        end
      end
    end
  end
end
