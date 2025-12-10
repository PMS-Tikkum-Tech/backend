class Booking < ApplicationRecord
  belongs_to :tenant, class_name: 'User'
  belongs_to :room
  has_one :property, through: :room

  # Enums
  enum status: {
    pending: 'pending',
    confirmed: 'confirmed',
    cancelled: 'cancelled',
    completed: 'completed',
    rejected: 'rejected'
  }

  # Validations
  validates :tenant, :room, :start_date, :end_date, :status, presence: true
  validates :total_price, numericality: { greater_than: 0 }
  validates :notes, length: { maximum: 1000 }, allow_blank: true
  validate :end_date_after_start_date
  validate :room_availability
  validate :tenant_cannot_book_own_room
  validate :start_date_not_in_past

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :pending, -> { where(status: 'pending') }
  scope :upcoming, -> { where('start_date >= ?', Date.current).where.not(status: 'cancelled') }
  scope :past, -> { where('end_date < ?', Date.current) }
  scope :by_tenant, ->(tenant) { where(tenant: tenant) }
  scope :by_room, ->(room) { where(room: room) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :calculate_total_price
  after_update :update_room_status, if: :saved_change_to_status?

  # Instance methods
  def duration_in_months
    ((end_date - start_date).to_i / 30.0).round(2)
  end

  def monthly_price
    room.price
  end

  def property_name
    room.property.title
  end

  def room_name
    room.name
  end

  def tenant_name
    tenant.full_name
  end

  def is_active?
    status == 'confirmed' && start_date <= Date.current && end_date >= Date.current
  end

  def is_upcoming?
    status == 'confirmed' && start_date > Date.current
  end

  def is_past?
    end_date < Date.current
  end

  def can_be_cancelled?
    ['pending', 'confirmed'].include?(status) && start_date > Date.current
  end

  def days_until_start
    return 0 if start_date <= Date.current
    (start_date - Date.current).to_i
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def room_availability
    return if room.blank? || start_date.blank? || end_date.blank?

    # Check for overlapping bookings
    overlapping_bookings = Booking.where(room: room)
                                 .where.not(id: id)
                                 .where(status: 'confirmed')
                                 .where('(start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?)',
                                       end_date, start_date, start_date, end_date)

    if overlapping_bookings.exists?
      errors.add(:base, "Room is not available for the selected dates")
    end
  end

  def tenant_cannot_book_own_room
    return if tenant.blank? || room.blank?

    if room.property.landlord == tenant
      errors.add(:base, "You cannot book your own property")
    end
  end

  def start_date_not_in_past
    return if start_date.blank?

    if start_date < Date.current
      errors.add(:start_date, "cannot be in the past")
    end
  end

  def calculate_total_price
    return if room.blank? || start_date.blank? || end_date.blank?

    duration_months = ((end_date - start_date).to_i / 30.0).ceil
    self.total_price = room.price * duration_months
  end

  def update_room_status
    return unless room.present?

    case status
    when 'confirmed'
      room.update!(status: 'occupied')
    when 'cancelled', 'rejected'
      # Check if there are other confirmed bookings
      other_bookings = Booking.where(room: room).where(status: 'confirmed').where.not(id: id)
      if other_bookings.empty?
        room.update!(status: 'available')
      end
    when 'completed'
      room.update!(status: 'available')
    end
  end
end
