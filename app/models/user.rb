# frozen_string_literal: true

class User < ApplicationRecord
  # BCrypt password hashing
  has_secure_password

  # Active Storage for profile photo
  has_one_attached :profile_photo

  # JWT token blacklisting
  has_many :revoked_tokens, dependent: :destroy

  # Only validate profile photo when it's being uploaded
  # Skip validation on login/logout operations
  validate :profile_photo_validation, on: %i[create update]

  # Enum for roles: 0 = owner, 1 = admin
  enum role: { owner: 0, admin: 1 }

  # Validations
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 },
                       if: :password_digest_changed?
  validates :first_name, presence: true

  # Scopes
  scope :by_role, ->(role) { where(role: roles[role.to_sym]) if role.present? }

  # Domain methods
  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def admin?
    role == 'admin'
  end

  def owner?
    role == 'owner'
  end

  def profile_photo_attached?
    profile_photo.attached?
  end

  def profile_photo_url
    return nil unless profile_photo_attached?

    Rails.application.routes.url_helpers.rails_blob_url(profile_photo,
                                                        only_path: true)
  end

  private

  def profile_photo_validation
    # Only validate if profile photo is actually attached
    # AND the attachment is being processed (not just existing)
    return unless profile_photo.attached?
    return if defined?(@_skip_photo_validation) && @_skip_photo_validation

    # Check content type
    unless profile_photo.content_type.in?(%w[image/png image/jpg image/jpeg])
      errors.add(:profile_photo, 'must be PNG, JPG, or JPEG')
    end

    # Check file size (5MB limit)
    return unless profile_photo.byte_size > 5.megabytes

    errors.add(:profile_photo, 'must be less than 5MB')
  end
end
