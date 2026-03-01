# frozen_string_literal: true

class SendCommunicationJob < ApplicationJob
  queue_as :default

  def perform(communication_id)
    communication = Communication.includes(:communication_recipients).find_by(
      id: communication_id,
    )
    return unless communication

    recipients = communication.communication_recipients
    if recipients.empty?
      communication.update!(status: :failed)
      return
    end

    recipients.find_each do |recipient|
      recipient.update!(status: :sent, sent_at: Time.current)
    rescue StandardError => exception
      recipient.update(
        status: :failed,
        failed_reason: exception.message,
      )
    end

    if recipients.where(status: :failed).exists?
      communication.update!(status: :failed)
    else
      communication.update!(status: :sent, sent_at: Time.current)
    end
  end
end
