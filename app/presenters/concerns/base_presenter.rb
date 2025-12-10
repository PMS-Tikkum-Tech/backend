# frozen_string_literal: true

# Base Presenter/Serializer untuk response mapping
# Fokus pada mapping → bentuk payload final, tanpa query dan side effects

module BasePresenter
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
  end

  class_methods do
    def from_collection(collection, current_user = nil)
      return [] if collection.blank?

      collection.map { |item| new(item, current_user) }
    end

    def paginate(collection, page = 1, per_page = 20)
      return {
        data: [],
        pagination: empty_pagination
      } if collection.blank?

      paginated = collection.offset((page - 1) * per_page)
                        .limit(per_page)

      {
        data: from_collection(paginated),
        pagination: pagination_metadata(collection, page, per_page)
      }
    end

    private

    def pagination_metadata(collection, page, per_page)
      total = collection.count
      total_pages = (total.to_f / per_page).ceil

      {
        current_page: page,
        per_page: per_page,
        total: total,
        total_pages: total_pages,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
    end

    def empty_pagination
      {
        current_page: 1,
        per_page: 20,
        total: 0,
        total_pages: 0,
        has_next_page: false,
        has_prev_page: false
      }
    end
  end

  def initialize(object, current_user = nil)
    @object = object
    @current_user = current_user
  end

  def to_hash
    # Override di subclass
    {}
  end

  def to_json(*args)
    to_hash.to_json(*args)
  end

  protected

  attr_reader :object, :current_user

  # Helper methods untuk formatting
  def format_currency(amount)
    return nil if amount.blank?

    "Rp #{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
  end

  def format_date(date)
    return nil if date.blank?
    date.strftime('%Y-%m-%d')
  end

  def format_datetime(datetime)
    return nil if datetime.blank?
    datetime.strftime('%Y-%m-%d %H:%M:%S')
  end

  def format_phone(phone)
    return nil if phone.blank?
    phone.gsub(/\D/, '')
  end

  def present_association(association, presenter_class = nil)
    return nil if association.blank?

    if presenter_class.present?
      presenter_class.new(association, current_user).to_hash
    elsif association.respond_to?(:map)
      association.map { |item| item.is_a?(Hash) ? item : { id: item.id, name: item.to_s } }
    else
      { id: association.id, name: association.to_s }
    end
  end

  def present_timestamps(model)
    return {} unless model.respond_to?(:created_at)

    {
      created_at: format_datetime(model.created_at),
      updated_at: format_datetime(model.updated_at)
    }
  end

  def present_photos(photos)
    return [] if photos.blank?

    photos.map do |photo|
      {
        id: photo.id,
        url: photo.image_url,
        thumbnail_url: photo.image_thumbnail_url,
        preview_url: photo.image_preview_url,
        title: photo.title,
        description: photo.description
      }
    end
  end

  def present_amenities(amenities)
    return [] if amenities.blank?

    amenities.map do |amenity|
      {
        id: amenity.id,
        name: amenity.name,
        description: amenity.description,
        category: amenity.category,
        icon_class: amenity.icon_class
      }
    end
  end

  def present_reviews_summary(reviews)
    return { average: 0, total: 0, distribution: {} } if reviews.blank?

    {
      average: reviews.average(:rating)&.round(2) || 0,
      total: reviews.count,
      distribution: calculate_rating_distribution(reviews)
    }
  end

  private

  def calculate_rating_distribution(reviews)
    distribution = { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
    reviews.group(:rating).count.each { |rating, count| distribution[rating] = count }
    distribution
  end

  def can_access_private_data?
    return false unless current_user.present?

    # Check if current_user can access private data
    current_user.admin? || (object.respond_to?(:landlord) && object.landlord == current_user)
  end
end