# frozen_string_literal: true

class MaintenanceRequestPresenter
  def self.collection(requests)
    requests.map { |request| as_json(request) }
  end

  def self.as_json(request)
    {
      id: request.id,
      property: {
        id: request.property_id,
        name: request.property&.name,
      },
      unit: {
        id: request.unit_id,
        name: request.unit&.name,
        unit_type: request.unit&.unit_type,
      },
      tenant: {
        id: request.tenant_id,
        full_name: request.tenant&.full_name,
      },
      assigned_to: {
        id: request.assigned_to_id,
        full_name: request.assigned_to&.full_name,
      },
      issue: request.issue,
      category: request.category,
      description: request.description,
      priority: request.priority,
      status: request.status,
      requested_date: request.requested_date,
      repair_date: request.repair_date,
      visiting_hours: request.visiting_hours,
      created_at: request.created_at&.iso8601,
      updated_at: request.updated_at&.iso8601,
    }
  end
end
