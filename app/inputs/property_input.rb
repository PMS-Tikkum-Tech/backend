# frozen_string_literal: true

# Input/DTO untuk Property creation dan update
# Melakukan normalisasi dan validasi property parameters

class PropertyInput
  include BaseInput

  attribute :title, :string
  attribute :description, :string
  attribute :address, :string
  attribute :city, :string
  attribute :province, :string
  attribute :postal_code, :string
  attribute :country, :string, default: 'Indonesia'
  attribute :property_type, :string
  attribute :accommodation_type, :string
  attribute :status, :string, default: 'draft'
  attribute :latitude, :float
  attribute :longitude, :float
  attribute :amenity_ids, array: true, default: []
  attribute :current_user, User

  validates :title, :description, :address, :city, :province, :postal_code, :country, presence: true
  validates :title, length: { minimum: 10, maximum: 200 }
  validates :description, length: { minimum: 50, maximum: 2000 }
  validates :property_type, :accommodation_type, presence: true
  validates :postal_code, format: { with: /\A\d{5}\z/, message: "must be a valid postal code" }
  validate :validate_property_type
  validate :validate_accommodation_type
  validate :validate_status
  validate :validate_coordinates

  def valid?
    super
  end

  def to_property_params
    # Return hash untuk property creation/update
    {
      title: title,
      description: description,
      address: address,
      city: city,
      province: province,
      postal_code: postal_code,
      country: country,
      property_type: property_type,
      accommodation_type: accommodation_type,
      status: status,
      latitude: latitude,
      longitude: longitude
    }.compact
  end

  private

  def apply_defaults(params)
    # Normalize country name
    params[:country] = params[:country]&.strip || 'Indonesia'

    # Normalize status
    params[:status] = 'draft' if params[:status].blank?

    # Normalize arrays
    params[:amenity_ids] = Array(params[:amenity_ids]).compact_blank
  end

  def custom_validations
    validate_complete_address
    validate_geographic_data
    validate_amenities
    true
  end

  def validate_property_type
    return true if property_type.blank?

    allowed_types = %w[kos apartment house villa)
    unless allowed_types.include?(property_type)
      errors.add(:property_type, "must be one of: #{allowed_types.join(', ')}")
    end
  end

  def validate_accommodation_type
    return true if accommodation_type.blank?

    allowed_types = %w(male female mixed)
    unless allowed_types.include?(accommodation_type)
      errors.add(:accommodation_type, "must be one of: #{allowed_types.join(', ')}")
    end
  end

  def validate_status
    return true if status.blank?

    allowed_statuses = %w(draft published archived rented)
    unless allowed_statuses.include?(status)
      errors.add(:status, "must be one of: #{allowed_statuses.join(', ')}")
    end
  end

  def validate_coordinates
    return true if latitude.blank? && longitude.blank?

    # Validasi latitude
    if latitude.present?
      unless latitude.is_a?(Numeric) && latitude.between?(-90, 90)
        errors.add(:latitude, "must be between -90 and 90")
      end
    end

    # Validasi longitude
    if longitude.present?
      unless longitude.is_a?(Numeric) && longitude.between?(-180, 180)
        errors.add(:longitude, "must be between -180 and 180")
      end
    end

    # Jika salah satu ada, keduanya harus ada
    if latitude.present? != longitude.present?
      errors.add(:base, "Both latitude and longitude must be provided together")
    end
  end

  def validate_complete_address
    # Basic address completeness check
    required_address_fields = [address, city, province, postal_code]
    return true if required_address_fields.all?(&:present?)

    errors.add(:base, "Complete address information is required")
    false
  end

  def validate_geographic_data
    # Validate that city and province are valid Indonesian regions (if needed)
    return true if city.blank? || province.blank?

    # Basic format validation
    unless city.match?(/\A[a-zA-Z\s]+\z/)
      errors.add(:city, "must contain only letters and spaces")
    end

    unless province.match?(/\A[a-zA-Z\s]+\z/)
      errors.add(:province, "must contain only letters and spaces")
    end
  end

  def validate_amenities
    return true if amenity_ids.blank?

    # Check if amenity_ids are valid
    valid_amenity_count = Amenity.where(id: amenity_ids).count
    if valid_amenity_count != amenity_ids.length
      errors.add(:amenity_ids, "contain invalid amenity IDs")
    end
  end
end