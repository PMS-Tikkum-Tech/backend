# frozen_string_literal: true

class Property < ApplicationRecord
  # Domain/Repository Layer
  # Fokus pada domain rules, asosiasi, scope, validasi

  belongs_to :landlord, class_name: 'User'
  has_many :rooms, dependent: :destroy
  has_many :photos, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_and_belongs_to_many :amenities

  # Enums
  enum property_type: { kos: 'kos', apartment: 'apartment', house: 'house', villa: 'villa' }
  enum accommodation_type: { male: 'male', female: 'female', mixed: 'mixed' }
  enum status: { draft: 'draft', published: 'published', archived: 'archived', rented: 'rented' }

  # Domain Validations
  validates :title, :description, :address, :city, :province, :postal_code, :country, presence: true
  validates :title, length: { minimum: 10, maximum: 200 }
  validates :description, length: { minimum: 50, maximum: 2000 }
  validates :property_type, :accommodation_type, :status, presence: true
  validates :postal_code, format: { with: /\A\d{5}\z/, message: "must be a valid postal code" }
  validates :landlord, presence: true

  # Domain Scopes
  scope :published, -> { where(status: 'published') }
  scope :by_property_type, ->(type) { where(property_type: type) }
  scope :by_accommodation_type, ->(type) { where(accommodation_type: type) }
  scope :by_city, ->(city) { where('city ILIKE ?', "%#{city}%") }
  scope :available, -> { where(status: 'published') }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods (domain-specific only)
  def full_address
    "#{address}, #{city}, #{province}, #{postal_code}, #{country}"
  end

  def main_photo
    photos.order(created_at: :asc).first
  end

  # Dihindari: business logic yang kompleks dipindahkan ke service layer
  # average_rating, min_price, max_price dipindahkan ke PropertyService
end
