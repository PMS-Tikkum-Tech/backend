# frozen_string_literal: true

class Unit < ApplicationRecord
  UNIT_TYPES = [
    "standard",
    "deluxe",
    "exclusive",
    "premium",
    "studio",
    "suite",
  ].freeze

  belongs_to :property

  has_many :leases, dependent: :destroy
  has_one :current_lease,
          -> { active.order(created_at: :desc) },
          class_name: "Lease",
          inverse_of: :unit
  has_many :maintenance_requests, dependent: :destroy
  has_many :financial_transactions, dependent: :nullify
  has_many :payments, dependent: :restrict_with_exception
  has_many_attached :photos

  enum status: {
    vacant: 0,
    occupied: 1,
    maintenance: 2,
  }

  validates :name, presence: true
  validates :unit_type, inclusion: { in: UNIT_TYPES }
  validates :people_allowed,
            numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than: 0 }
  validate :photos_format

  def photo_urls
    photos.map do |photo|
      Rails.application.routes.url_helpers.rails_blob_path(
        photo,
        only_path: true,
      )
    end
  end

  def roomphoto_urls
    photo_urls
  end

  private

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
end
