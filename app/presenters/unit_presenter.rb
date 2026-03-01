# frozen_string_literal: true

class UnitPresenter
  def self.collection(units)
    units.map { |unit| as_json(unit) }
  end

  def self.as_json(unit)
    {
      id: unit.id,
      name: unit.name,
      unit_type: unit.unit_type,
      status: unit.status,
      people_allowed: unit.people_allowed,
      price: unit.price.to_f,
      roomphoto_urls: unit.roomphoto_urls,
      current_lease: lease_data(unit.current_lease),
      photo_urls: unit.photo_urls,
      created_at: unit.created_at&.iso8601,
      updated_at: unit.updated_at&.iso8601,
      property: property_data(unit.property),
    }
  end

  def self.property_data(property)
    return nil unless property

    {
      id: property.id,
      name: property.name,
      address: property.address,
      facilities: property.facilities
    }
  end

  def self.lease_data(lease)
    return nil unless lease

    {
      id: lease.id,
      tenant_name: lease.tenant&.full_name,
      start_date: lease.start_date,
      end_date: lease.end_date,
      lease_status: lease.lease_status,
      payment_status: lease.payment_status,
    }
  end
end
