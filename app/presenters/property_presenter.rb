# frozen_string_literal: true

class PropertyPresenter
  def self.list(properties)
    properties.map { |property| list_item(property) }
  end

  def self.list_item(property)
    {
      id: property.id,
      name: property.name,
      address: property.address,
      facilities: property.facilities,
      property_type: property.property_type,
      condition: property.condition,
      rules: property.rules,
      user: owner_data(property.user),
      total_units: property.total_units,
      occupied_units: property.occupied_units_count,
      vacant_units: property.vacant_units_count,
      maintenance_units: property.maintenance_units_count,
      roomphoto_urls: property.roomphoto_urls,
      photo_urls: property.photo_urls,
      created_at: property.created_at&.iso8601,
      updated_at: property.updated_at&.iso8601,
    }
  end

  def self.detail(property)
    {
      property: {
        id: property.id,
        name: property.name,
        property_type: property.property_type,
        address: property.address,
        description: property.description,
        condition: property.condition,
        facilities: property.facilities,
        rules: property.rules,
        roomphoto_urls: property.roomphoto_urls,
        user: owner_data(property.user),
        photo_urls: property.photo_urls,
        created_at: property.created_at&.iso8601,
        updated_at: property.updated_at&.iso8601,
      },
      stats: {
        description: property.description,
        address: property.address,
        total_units: property.total_units,
        occupied_units: property.occupied_units_count,
        vacant_units: property.vacant_units_count,
        maintenance_units: property.maintenance_units_count,
        total_tenants: property.total_tenants,
        price_range: property.price_range,
      }
    }
  end

  def self.tenant_rows(leases)
    leases.map do |lease|
      {
        lease_id: lease.id,
        tenant_name: lease.tenant.full_name,
        unit_id: lease.unit.id,
        unit_name: lease.unit.name,
        mobile_phone: lease.tenant.phone_number,
        lease_end: lease.end_date,
        payment_status: lease.payment_status,
      }
    end
  end

  def self.unit_rows(units)
    units.map do |unit|
      {
        unit_id: unit.id,
        unit_name: unit.name,
        unit_type: unit.unit_type,
        tenant_name: unit.current_lease&.tenant&.full_name,
        price: unit.price.to_f,
        lease_end: unit.current_lease&.end_date,
        status: unit.status,
      }
    end
  end

  def self.maintenance_rows(maintenance_requests)
    maintenance_requests.map do |request|
      {
        id: request.id,
        date: request.requested_date,
        unit_name: request.unit.name,
        unit_type: request.unit.unit_type,
        tenant_name: request.tenant.full_name,
        issue: request.issue,
        category: request.category,
        priority: request.priority,
        status: request.status,
        technician_name: request.assigned_to&.full_name,
      }
    end
  end

  def self.owner_data(user)
    return nil unless user

    {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      role: user.role,
    }
  end
end
