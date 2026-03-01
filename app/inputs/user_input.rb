# frozen_string_literal: true

class UserInput
  include BaseInput

  attr_accessor :full_name, :email, :password, :phone_number, :role,
                :account_status, :profile_picture, :search, :page, :per_page,
                :emergency_contact_name, :emergency_contact_number,
                :relationship, :nik

  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 },
                        on: :create
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                    on: :create
  validates :password, presence: true, length: { minimum: 8 }, on: :create

  validate :role_supported, on: [:create, :update]
  validate :account_status_supported, on: [:create, :update]
  validate :email_format_on_update, on: :update
  validate :password_length_on_update, on: :update

  def self.from_create_params(params)
    new(
      full_name: params[:full_name],
      email: params[:email],
      password: params[:password],
      phone_number: params[:phone_number],
      emergency_contact_name: params[:emergency_contact_name],
      emergency_contact_number: params[:emergency_contact_number],
      relationship: params[:relationship],
      nik: params[:nik],
      role: params[:role],
      account_status: params[:account_status],
      profile_picture: params[:profile_picture],
    )
  end

  def self.from_update_params(params)
    new(
      full_name: params[:full_name],
      email: params[:email],
      password: params[:password],
      phone_number: params[:phone_number],
      emergency_contact_name: params[:emergency_contact_name],
      emergency_contact_number: params[:emergency_contact_number],
      relationship: params[:relationship],
      nik: params[:nik],
      role: params[:role],
      account_status: params[:account_status],
      profile_picture: params[:profile_picture],
    )
  end

  def self.from_filter_params(params)
    new(
      search: params[:search],
      role: params[:role],
      account_status: params[:account_status],
      page: params[:page],
      per_page: params[:per_page],
    )
  end

  def to_create_h
    {
      full_name: full_name,
      email: email.to_s.downcase.strip,
      phone_number: phone_number,
      emergency_contact_name: emergency_contact_name,
      emergency_contact_number: emergency_contact_number,
      relationship: relationship,
      nik: nik,
      password: password,
      role: role || "tenant",
      account_status: account_status || "active",
      profile_picture: profile_picture,
    }
  end

  def to_update_h
    {
      full_name: full_name,
      email: email&.to_s&.downcase&.strip,
      password: password,
      phone_number: phone_number,
      emergency_contact_name: emergency_contact_name,
      emergency_contact_number: emergency_contact_number,
      relationship: relationship,
      nik: nik,
      role: role,
      account_status: account_status,
      profile_picture: profile_picture,
    }.compact
  end

  def to_filter_h
    {
      search: search,
      role: role,
      account_status: account_status,
      page: (page.presence || 1).to_i,
      per_page: [(per_page.presence || 10).to_i, 100].min,
    }.compact
  end

  private

  def role_supported
    return if role.blank?

    valid_roles = [
      "owner",
      "admin",
      "tenant",
      "0",
      "1",
      "2",
      0,
      1,
      2,
    ]
    return if valid_roles.include?(role)

    errors.add(:role, "is not supported")
  end

  def account_status_supported
    return if account_status.blank?

    valid_values = ["active", "inactive", "0", "1", 0, 1]
    return if valid_values.include?(account_status)

    errors.add(:account_status, "is not supported")
  end

  def email_format_on_update
    return if email.blank?
    return if email.match?(URI::MailTo::EMAIL_REGEXP)

    errors.add(:email, "is invalid")
  end

  def password_length_on_update
    return if password.blank?
    return if password.length >= 8

    errors.add(:password, "is too short (minimum is 8 characters)")
  end
end
