# frozen_string_literal: true

class Property < ApplicationRecord
  PROPERTY_TYPES = [
    "apartment",
    "house",
    "kost",
    "villa",
    "studio_apartment",
    "townhouse",
  ].freeze
  CONDITIONS = ["excellent", "good", "fair", "maintenance"].freeze
  AVAILABLE_FACILITIES = [
    "wifi",
    "parking_area",
    "kitchen",
    "pet_friendly",
    "cctv",
    "ac",
    "laundry",
    "swimming_pool",
    "gym",
    "security_24h",
    "elevator",
    "generator_backup",
    "balcony",
    "furnished",
    "garden",
    "rooftop_access",
  ].freeze

  belongs_to :user

  has_many :units, dependent: :destroy
  has_many :leases, through: :units
  has_many :tenants, through: :leases, source: :tenant
  has_many :maintenance_requests, dependent: :destroy
  has_many :financial_transactions, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :communications, dependent: :nullify
  has_many_attached :photos

  validates :name, presence: true
  validates :address, presence: true
  validates :property_type, inclusion: { in: PROPERTY_TYPES }
  validates :condition, inclusion: { in: CONDITIONS }
  validate :facilities_values_are_supported
  validate :photos_count_max_ten
  validate :photos_format
  validate :property_owner_role

  scope :by_property_type, ->(value) { where(property_type: value) }
  scope :by_condition, ->(value) { where(condition: value) }
  scope :search, lambda { |query|
    term = "%#{query}%"
    where("name ILIKE ? OR address ILIKE ?", term, term)
  }

  def total_units
    units.count
  end

  def occupied_units_count
    units.occupied.count
  end

  def vacant_units_count
    units.vacant.count
  end

  def maintenance_units_count
    units.maintenance.count
  end

  def total_tenants
    leases.active.distinct.count(:tenant_id)
  end

  def price_range
    {
      min: units.minimum(:price) || 0,
      max: units.maximum(:price) || 0,
    }
  end

  def roomphoto_urls
    photos.map do |photo|
      Rails.application.routes.url_helpers.rails_blob_path(
        photo,
        only_path: true,
      )
    end
  end

  def photo_urls
    roomphoto_urls
  end

  private

  def facilities_values_are_supported
    values = facilities || []
    return if values.is_a?(Array) && values.all? do |facility|
      AVAILABLE_FACILITIES.include?(facility)
    end

    errors.add(:facilities, "contains unsupported values")
  end

  def photos_count_max_ten
    return unless photos.attachments.size > 10

    errors.add(:photos, "maximum 10 photos")
  end

  def photos_format
    return unless photos.attached?

    allowed_types = [
      "application/pdf",
      "image/jpeg",
      "image/jpg",
      "image/png",
    ]
    photos.each do |photo|
      next if allowed_types.include?(photo.blob.content_type)

      errors.add(:photos, "must be PDF, PNG, JPG, or JPEG")
    end
  end

  def property_owner_role
    return if user.blank? || user.owner?

    errors.add(:user, "must have role owner")
  end
end
