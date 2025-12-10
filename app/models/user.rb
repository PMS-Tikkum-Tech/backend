class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  include DeviseTokenAuth::Concerns::User

  # User roles
  enum role: { tenant: 'tenant', landlord: 'landlord', admin: 'admin' }

  # Associations
  has_many :properties, foreign_key: :landlord_id, dependent: :destroy
  has_many :bookings, foreign_key: :tenant_id, dependent: :destroy
  has_many :reviews, dependent: :destroy

  # Validations
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :first_name, :last_name, presence: true
  validates :phone_number, format: { with: /\A\d{10,15}\z/, message: "must be a valid phone number" }, allow_blank: true

  # Callbacks
  after_initialize :set_default_role, if: :new_record?

  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :active, -> { where(active: true) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def active_for_authentication?
    super && active?
  end

  private

  def set_default_role
    self.role ||= 'tenant'
  end
end
