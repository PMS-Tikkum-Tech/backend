class Amenity < ApplicationRecord
  has_and_belongs_to_many :properties

  # Enums
  enum category: {
    facility: 'facility',
    room: 'room',
    bathroom: 'bathroom',
    kitchen: 'kitchen',
    security: 'security',
    internet: 'internet',
    entertainment: 'entertainment',
    other: 'other'
  }

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :category, presence: true

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :alphabetical, -> { order(:name) }
  scope :popular, -> { left_joins(:properties).group('amenities.id').order('COUNT(properties.id) DESC') }

  # Instance methods
  def icon_class
    return icon if icon.present?

    case category
    when 'facility'
      'fas fa-building'
    when 'room'
      'fas fa-bed'
    when 'bathroom'
      'fas fa-shower'
    when 'kitchen'
      'fas fa-utensils'
    when 'security'
      'fas fa-shield-alt'
    when 'internet'
      'fas fa-wifi'
    when 'entertainment'
      'fas fa-tv'
    else
      'fas fa-check-circle'
    end
  end

  def properties_count
    properties.count
  end
end
