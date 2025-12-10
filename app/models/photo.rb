class Photo < ApplicationRecord
  belongs_to :property
  belongs_to :room, optional: true

  # Active Storage attachment
  has_one_attached :image

  # Validations
  validates :title, length: { minimum: 3, maximum: 100 }, allow_blank: true
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :image, presence: true

  # Image validation
  validate :image_format_validation
  validate :image_size_validation

  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  scope :featured, -> { where(is_featured: true) }

  # Instance methods
  def image_url(size = :medium)
    if image.attached?
      if Rails.env.production?
        # In production, return the S3 URL
        image.url
      else
        # In development, return the local URL
        Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
      end
    end
  end

  def image_thumbnail_url
    if image.attached?
      image.variant(resize_to_limit: [300, 200]).processed.url
    end
  end

  def image_preview_url
    if image.attached?
      image.variant(resize_to_limit: [800, 600]).processed.url
    end
  end

  def file_size
    return 0 unless image.attached?
    image.blob.byte_size
  end

  def file_size_human
    ActiveSupport::NumberHelper.number_to_human_size(file_size)
  end

  def content_type
    return nil unless image.attached?
    image.blob.content_type
  end

  private

  def image_format_validation
    return unless image.attached?

    acceptable_types = ["image/jpeg", "image/png", "image/webp"]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, or WebP file")
    end
  end

  def image_size_validation
    return unless image.attached?

    max_size = 5.megabytes
    if image.blob.byte_size > max_size
      errors.add(:image, "must be less than 5MB")
    end
  end
end
