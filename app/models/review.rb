class Review < ApplicationRecord
  belongs_to :tenant, class_name: 'User'
  belongs_to :property

  # Validations
  validates :tenant, :property, :rating, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, length: { minimum: 10, maximum: 1000 }
  validates :tenant, uniqueness: { scope: :property, message: "can only review a property once" }

  # Scopes
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_tenant, ->(tenant) { where(tenant: tenant) }
  scope :by_property, ->(property) { where(property: property) }
  scope :with_comment, -> { where.not(comment: [nil, '']) }

  # Callbacks
  after_create :update_property_average_rating
  after_update :update_property_average_rating
  after_destroy :update_property_average_rating

  # Instance methods
  def tenant_name
    tenant.full_name
  end

  def property_name
    property.title
  end

  def rating_stars
    '⭐' * rating
  end

  def rating_percentage
    (rating / 5.0) * 100
  end

  def is_positive?
    rating >= 4
  end

  def is_neutral?
    rating == 3
  end

  def is_negative?
    rating <= 2
  end

  def formatted_created_at
    created_at.strftime('%B %d, %Y')
  end

  def can_be_edited_by?(user)
    tenant == user && created_at > 30.days.ago
  end

  def can_be_deleted_by?(user)
    tenant == user
  end

  private

  def update_property_average_rating
    return unless property.present?

    avg_rating = property.reviews.average(:rating)&.round(2) || 0
    property.update_column(:average_rating, avg_rating)
    property.update_column(:total_reviews, property.reviews.count)
  end
end
