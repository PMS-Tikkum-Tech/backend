# frozen_string_literal: true

# Base Input/DTO untuk validasi dan normalisasi params
# Fokus pada normalisasi param (coerce types, strip, default) dan validasi wajib

module BaseInput
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveModel::Attributes
  end

  class_methods do
    def from_params(params, current_user = nil)
      # Normalisasi params
      normalized_params = normalize_params(params)

      # Initialize with normalized params
      new(normalized_params.merge(current_user: current_user))
    end
  end

  def to_h
    attributes.with_indifferent_access
  end

  def valid?
    super && custom_validations
  end

  private

  def normalize_params(params)
    # Normalisasi default - override di subclass
    normalized = params.respond_to?(:to_h) ? params.to_h : params.dup

    # Strip string values
    normalized.each do |key, value|
      normalized[key] = value.strip if value.is_a?(String)
    end

    # Set defaults
    apply_defaults(normalized)

    normalized
  end

  def apply_defaults(params)
    # Override di subclass
  end

  def custom_validations
    # Override di subclass untuk custom validations
    true
  end

  def require_fields(*fields)
    missing = fields.select { |field| send(field).blank? }
    return true if missing.empty?

    missing.each do |field|
      errors.add(field, "can't be blank")
    end
    false
  end

  def validate_enum(field, allowed_values)
    return true if send(field).blank? || allowed_values.include?(send(field))

    errors.add(field, "must be one of: #{allowed_values.join(', ')}")
    false
  end

  def validate_email_format(field)
    email = send(field)
    return true if email.blank?

    unless email.match?(/\A[^@\s]+@[^@\s]+\z/)
      errors.add(field, "must be a valid email address")
      return false
    end
    true
  end

  def validate_phone_format(field)
    phone = send(field)
    return true if phone.blank?

    unless phone.match?(/\A\d{10,15}\z/)
      errors.add(field, "must be a valid phone number")
      return false
    end
    true
  end

  def validate_positive_number(field)
    value = send(field)
    return true if value.blank?

    unless value.to_f > 0
      errors.add(field, "must be a positive number")
      return false
    end
    true
  end

  def validate_date_range(start_date_field, end_date_field)
    start_date = send(start_date_field)
    end_date = send(end_date_field)

    return true if start_date.blank? || end_date.blank?

    if end_date <= start_date
      errors.add(end_date_field, "must be after #{start_date_field}")
      return false
    end
    true
  end
end