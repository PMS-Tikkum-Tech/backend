class Room < ApplicationRecord
  belongs_to :property
  has_many :bookings, dependent: :destroy
  has_many :photos, dependent: :destroy

  # Enums
  enum status: { available: 'available', occupied: 'occupied', maintenance: 'maintenance', unavailable: 'unavailable' }

  # Validations
  validates :name, :price, :size, :capacity, :status, presence: true
  validates :name, length: { minimum: 3, maximum: 100 }
  validates :price, numericality: { greater_than: 0 }
  validates :size, numericality: { greater_than: 0 }
  validates :capacity, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :by_price_range, ->(min_price, max_price) { where(price: min_price..max_price) }
  scope :by_capacity, ->(capacity) { where('capacity >= ?', capacity) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def is_available?
    status == 'available'
  end

  def is_occupied?
    status == 'occupied'
  end

  def current_booking
    bookings.where(status: 'confirmed').where('start_date <= ? AND end_date >= ?', Date.current, Date.current).first
  end

  def available_dates(start_date, end_date)
    return [] unless is_available?

    # Get all occupied dates for this room
    occupied_bookings = bookings.where(status: 'confirmed')
                             .where.not(end_date: nil)
                             .where('(start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?)',
                                   end_date, start_date, start_date, end_date)

    occupied_dates = occupied_bookings.flat_map do |booking|
      (booking.start_date..booking.end_date).to_a
    end.uniq

    # Return available dates
    (start_date..end_date).to_a - occupied_dates
  end

  def format_size
    "#{size} m²"
  end

  def price_per_month
    price
  end

  def formatted_price
    "Rp #{price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
  end
end
