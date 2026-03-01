# frozen_string_literal: true

class CommunicationPresenter
  def self.collection(communications)
    communications.map { |communication| as_json(communication) }
  end

  def self.as_json(communication)
    {
      id: communication.id,
      date: communication.scheduled_at&.to_date&.iso8601,
      target_property: target_property(communication),
      property: {
        id: communication.property_id,
        name: communication.property&.name,
        property_type: communication.property&.property_type,
      },
      subject: communication.subject,
      message: communication.message,
      audience_type: communication.audience_type,
      audience_label: audience_label(communication),
      audience: audience_label(communication),
      recipients: recipient_rows(communication),
      status: communication.status,
      recipient_count: communication.communication_recipients.size,
      time: communication.scheduled_at&.strftime("%H:%M"),
      date_time: communication.scheduled_at&.strftime("%Y-%m-%d %H:%M"),
      scheduled_at: communication.scheduled_at&.iso8601,
      sent_at: communication.sent_at&.iso8601,
      created_by: {
        id: communication.created_by_id,
        full_name: communication.created_by&.full_name,
      },
      created_at: communication.created_at&.iso8601,
      updated_at: communication.updated_at&.iso8601,
    }
  end

  def self.recipient_rows(communication)
    communication.communication_recipients.map do |recipient|
      {
        tenant_id: recipient.tenant_id,
        tenant_name: recipient.tenant&.full_name,
        status: recipient.status,
        sent_at: recipient.sent_at&.iso8601,
        failed_reason: recipient.failed_reason,
      }
    end
  end

  def self.target_property(communication)
    communication.property&.name || "All Properties"
  end

  def self.audience_label(communication)
    map = {
      "all_tenants" => "All Tenants",
      "some_tenants" => "Private",
      "specific_tenants" => "Specific Tenants",
    }

    map.fetch(
      communication.audience_type,
      communication.audience_type.to_s.humanize,
    )
  end
end
