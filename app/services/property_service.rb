# frozen_string_literal: true

# Service Layer untuk Property business logic
# Fokus pada use cases untuk property management

class PropertyService
  include BaseService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :property, Property
  attribute :current_user, User
  attribute :filters, default: -> {}

  def initialize(property: nil, current_user: nil, filters: {})
    @property = property
    @current_user = current_user
    @filters = filters
  end

  # Use Case: Get property with calculated data
  def show
    return failure(['Property not found'], 'Property not found') unless property

    # Eager load untuk prevent N+1
    property_data = Property.includes(:rooms, :photos, :reviews, :amenities, :landlord)
                            .find(property.id)

    success(property_data, 'Property retrieved successfully')
  end

  # Use Case: Search properties dengan kompleks filtering
  def search
    properties = Property.published
                     .includes(:rooms, :photos, :landlord) # Eager load

    # Apply filters
    properties = apply_property_type_filter(properties)
    properties = apply_accommodation_type_filter(properties)
    properties = apply_city_filter(properties)
    properties = apply_price_range_filter(properties)

    # Add calculated data untuk hasil search
    properties_with_data = properties.map do |prop|
      prop_with_calculations(prop)
    end

    success(properties_with_data, 'Properties retrieved successfully')
  end

  # Use Case: Create property
  def create(property_params)
    transaction do
      @property = Property.new(property_params)
      @property.landlord = current_user

      if @property.save
        success(@property, 'Property created successfully')
      else
        failure(@property.errors.full_messages, 'Failed to create property')
      end
    end
  end

  # Use Case: Update property
  def update(property_params)
    return failure(['Property not found'], 'Property not found') unless property
    return failure(['Access denied'], 'Access denied') unless can_update?

    transaction do
      if property.update(property_params)
        success(property, 'Property updated successfully')
      else
        failure(property.errors.full_messages, 'Failed to update property')
      end
    end
  end

  # Use Case: Delete property
  def destroy
    return failure(['Property not found'], 'Property not found') unless property
    return failure(['Access denied'], 'Access denied') unless can_destroy?

    transaction do
      if property.destroy
        success(nil, 'Property deleted successfully')
      else
        failure(property.errors.full_messages, 'Failed to delete property')
      end
    end
  end

  # Use Case: Get property statistics
  def statistics
    return failure(['Property not found'], 'Property not found') unless property

    stats = {
      total_reviews: property.reviews.count,
      average_rating: calculate_average_rating(property),
      total_rooms: property.rooms.count,
      available_rooms: property.rooms.available.count,
      min_price: calculate_min_price(property),
      max_price: calculate_max_price(property),
      total_bookings: total_bookings_count
    }

    success(stats, 'Statistics retrieved successfully')
  end

  private

  def apply_property_type_filter(properties)
    return properties unless filters[:property_type].present?
    properties.by_property_type(filters[:property_type])
  end

  def apply_accommodation_type_filter(properties)
    return properties unless filters[:accommodation_type].present?
    properties.by_accommodation_type(filters[:accommodation_type])
  end

  def apply_city_filter(properties)
    return properties unless filters[:city].present?
    properties.by_city(filters[:city])
  end

  def apply_price_range_filter(properties)
    return properties if filters[:min_price].blank? && filters[:max_price].blank?

    # Eager load rooms untuk price filtering
    properties = properties.includes(:rooms)

    if filters[:min_price].present? || filters[:max_price].present?
      properties = properties.select('properties.*')
                                 .joins('LEFT JOIN rooms ON rooms.property_id = properties.id AND rooms.status = \'available\'')
                                 .group('properties.id')
    end

    properties = properties.having('MIN(rooms.price) >= ?', filters[:min_price]) if filters[:min_price].present?
    properties = properties.having('MIN(rooms.price) <= ?', filters[:max_price]) if filters[:max_price].present?

    properties
  end

  def prop_with_calculations(prop)
    # Gunakan OpenStruct untuk menambahkan calculated data tanpa mengubah model
    OpenStruct.new(
      prop.attributes.merge(
        average_rating: calculate_average_rating(prop),
        total_reviews: prop.reviews.count,
        min_price: calculate_min_price(prop),
        max_price: calculate_max_price(prop),
        main_photo: prop.main_photo
      )
    )
  end

  def calculate_average_rating(prop)
    return 0 if prop.reviews.empty?
    prop.reviews.average(:rating).round(2)
  end

  def calculate_min_price(prop)
    prop.rooms.available.minimum(:price) || 0
  end

  def calculate_max_price(prop)
    prop.rooms.available.maximum(:price) || 0
  end

  def total_bookings_count
    return 0 unless property.present?
    Booking.joins(:room).where(rooms: { property: property }).count
  end

  def can_update?
    current_user.present? && (
      current_user.admin? || (property.landlord == current_user)
    )
  end

  def can_destroy?
    can_update?
  end
end