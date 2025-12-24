# frozen_string_literal: true

# Unified AuthInput for all authentication and user-related inputs
# Handles login, create user, update user, and filtering
class AuthInput
  include BaseInput

  # Login attributes
  attr_accessor :email, :password

  # Create user attributes
  attr_accessor :first_name, :last_name, :phone, :role, :profile_photo

  # Update user attributes
  attr_accessor :remove_profile_photo

  # Filter attributes
  attr_accessor :search, :page, :per_page, :role

  # Context for validation
  attr_accessor :context

  # Login validations
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    on: :login
  validates :password, presence: true, on: :login

  # Create user validations
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    on: :create
  validates :password, presence: true, length: { minimum: 8 }, on: :create
  validates :first_name, presence: true, on: :create
  validates :role, inclusion: { in: %w[admin owner] },
                   allow_blank: true, on: :create

  # Class methods for creating inputs with context
  def self.login_params(params)
    input = new(params.slice(:email, :password))
    input.context = :login
    input
  end

  def self.create_params(params)
    input = new(params.slice(:email, :password, :first_name,
                             :last_name, :phone, :role, :profile_photo))
    input.context = :create
    input
  end

  def self.update_params(params)
    input = new(params.slice(:first_name, :last_name, :phone,
                             :profile_photo, :remove_profile_photo))
    input.context = :update
    input
  end

  def self.filter_params(params)
    new(params.slice(:search, :page, :per_page, :role))

  end

  # Convert to login params hash
  def to_login_params
    {
      email: email,
      password: password
    }.compact
  end

  # Convert to create user params hash
  def to_create_params
    {
      email: email,
      password: password,
      password_confirmation: password,
      first_name: first_name,
      last_name: last_name,
      phone: phone,
      role: role || 'owner',
      profile_photo: profile_photo
    }.compact
  end

  # Convert to update user params hash
  def to_update_params
    params = {}

    # Add fields if present (all optional for PATCH)
    params[:first_name] = first_name if first_name
    params[:last_name] = last_name if last_name
    params[:phone] = phone if phone

    # Include profile_photo if present
    params[:profile_photo] = profile_photo if profile_photo
    # Handle remove_profile_photo flag
    params[:remove_profile_photo] = remove_profile_photo if remove_profile_photo

    params
  end

  # Convert to filter params hash
  def to_filter_params
    {
      search: search,
      page: page&.to_i || 1,
      per_page: [per_page&.to_i || 20, 100].min,
      role: role
    }.compact
  end
end
