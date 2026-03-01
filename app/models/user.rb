# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_one_attached :profile_picture

  has_many :revoked_tokens, dependent: :destroy
  has_many :admin_log_activities,
           class_name: "LogActivity",
           foreign_key: :admin_id,
           inverse_of: :admin,
           dependent: :restrict_with_exception
  has_many :properties, dependent: :restrict_with_exception
  has_many :leases_as_tenant,
           class_name: "Lease",
           foreign_key: :tenant_id,
           inverse_of: :tenant,
           dependent: :restrict_with_exception
  has_many :maintenance_requests_as_tenant,
           class_name: "MaintenanceRequest",
           foreign_key: :tenant_id,
           inverse_of: :tenant,
           dependent: :restrict_with_exception
  has_many :maintenance_requests_as_technician,
           class_name: "MaintenanceRequest",
           foreign_key: :assigned_to_id,
           inverse_of: :assigned_to,
           dependent: :nullify
  has_many :financial_transactions_created,
           class_name: "FinancialTransaction",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_exception
  has_many :payments_as_tenant,
           class_name: "Payment",
           foreign_key: :tenant_id,
           inverse_of: :tenant,
           dependent: :restrict_with_exception
  has_many :communications_created,
           class_name: "Communication",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_exception
  has_many :communication_recipients_as_tenant,
           class_name: "CommunicationRecipient",
           foreign_key: :tenant_id,
           inverse_of: :tenant,
           dependent: :restrict_with_exception

  enum role: {
    owner: 0,
    admin: 1,
    tenant: 2,
  }

  enum account_status: {
    active: 0,
    inactive: 1,
  }

  before_validation :normalize_email

  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true
  validates :account_status, presence: true
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
  validate :profile_picture_type
  validate :profile_picture_size

  scope :active_users, -> { where(account_status: :active) }

  def profile_picture_url
    return nil unless profile_picture.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      profile_picture,
      only_path: true,
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def profile_picture_type
    return unless profile_picture.attached?

    allowed_types = ["image/jpeg", "image/jpg", "image/png"]
    return if allowed_types.include?(profile_picture.content_type)

    errors.add(:profile_picture, "must be PNG, JPG, or JPEG")
  end

  def profile_picture_size
    return unless profile_picture.attached?
    return unless profile_picture.blob.byte_size > 5.megabytes

    errors.add(:profile_picture, "must be less than 5 MB")
  end
end
