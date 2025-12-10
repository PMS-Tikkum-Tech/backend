# frozen_string_literal: true

# Presenter untuk Property response
# Mapping property data ke API response format tanpa query tambahan

class PropertyPresenter
  include BasePresenter

  def to_hash
    hash = {
      id: object.id,
      title: object.title,
      description: object.description,
      address: object.full_address,
      city: object.city,
      province: object.province,
      property_type: object.property_type,
      accommodation_type: object.accommodation_type,
      status: object.status,
      coordinates: present_coordinates,
      pricing: present_pricing,
      availability: present_availability,
      reviews: present_reviews_summary(object.reviews),
      photos: present_photos(object.photos.limit(5)), # Limit to prevent large payloads
      amenities: present_amenities(object.amenities),
      landlord: present_landlord_info,
      stats: present_property_stats
    }

    hash.merge!(present_timestamps(object))
    hash
  end

  private

  def present_coordinates
    return nil unless object.latitude.present? && object.longitude.present?

    {
      latitude: object.latitude.round(6),
      longitude: object.longitude.round(6)
    }
  end

  def present_pricing
    # Use calculated data from service layer if available
    if object.respond_to?(:min_price) && object.respond_to?(:max_price)
      {
        min_price: object.min_price,
        max_price: object.max_price,
        currency: 'IDR',
        formatted_min_price: format_currency(object.min_price),
        formatted_max_price: format_currency(object.max_price)
      }
    else
      {
        min_price: 0,
        max_price: 0,
        currency: 'IDR',
        formatted_min_price: format_currency(0),
        formatted_max_price: format_currency(0)
      }
    end
  end

  def present_availability
    {
      total_rooms: object.rooms&.count || 0,
      available_rooms: object.rooms&.available&.count || 0,
      is_available: object.status == 'published'
    }
  end

  def present_landlord_info
    landlord = object.landlord
    return nil unless landlord.present?

    # Public info only
    {
      id: landlord.id,
      name: landlord.full_name,
      phone: can_access_private_data? ? landlord.phone_number : nil
    }.compact
  end

  def present_property_stats
    {
      total_reviews: object.reviews.count,
      average_rating: object.respond_to?(:average_rating) ? object.average_rating : 0,
      total_rooms: object.rooms.count,
      available_rooms: object.rooms.available.count
    }
  end

  # Detail presenter untuk single property view
  class Detail < self
    def to_hash
      hash = super

      # Add more detailed info for single property view
      hash[:photos] = present_photos(object.photos)
      hash[:rooms] = present_rooms
      hash[:reviews] = present_recent_reviews
      hash[:booking_stats] = present_booking_stats

      hash
    end

    private

    def present_rooms
      return [] unless object.rooms.present?

      object.rooms.map do |room|
        {
          id: room.id,
          name: room.name,
          description: room.description,
          size: room.size,
          capacity: room.capacity,
          price: room.price,
          formatted_price: format_currency(room.price),
          size_formatted: room.format_size,
          status: room.status,
          is_available: room.is_available?
        }
      end
    end

    def present_recent_reviews
      return [] unless object.reviews.present?

      object.reviews.recent.limit(5).map do |review|
        {
          id: review.id,
          rating: review.rating,
          comment: review.comment,
          created_at: format_date(review.created_at),
          tenant_name: review.tenant_name
        }
      end
    end

    def present_booking_stats
      # Enhanced statistics for property owner
      stats = present_property_stats

      if can_access_private_data?
        total_bookings = Booking.joins(:room)
                             .where(rooms: { property: object })
                             .count

        confirmed_bookings = Booking.joins(:room)
                                  .where(rooms: { property: object })
                                  .where(status: 'confirmed')
                                  .count

        stats.merge!(
          total_bookings: total_bookings,
          confirmed_bookings: confirmed_bookings,
          occupancy_rate: calculate_occupancy_rate
        )
      end

      stats
    end

    def calculate_occupancy_rate
      total_rooms = object.rooms.count
      return 0 if total_rooms == 0

      occupied_rooms = object.rooms.where(status: 'occupied').count
      ((occupied_rooms.to_f / total_rooms) * 100).round(2)
    end
  end

  # Search result presenter (lighter version)
  class SearchResult < self
    def to_hash
      # Lighter version for search results
      {
        id: object.id,
        title: object.title,
        address: object.full_address,
        city: object.city,
        property_type: object.property_type,
        accommodation_type: object.accommodation_type,
        pricing: present_pricing,
        availability: present_availability,
        reviews: present_reviews_summary(object.reviews),
        photos: present_photos(object.photos.limit(2)), # Only 2 photos for list view
        main_photo: object.main_photo&.image_url,
        rating: object.respond_to?(:average_rating) ? object.average_rating : 0
      }
    end
  end
end