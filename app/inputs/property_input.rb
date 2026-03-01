# frozen_string_literal: true

class PropertyInput
  include BaseInput

  attr_accessor :name, :description, :address, :property_type, :condition,
                :facilities, :user_id, :rules, :roomphotos,
                :photos, :search, :sort, :page,
                :per_page, :status, :unit_type, :priority

  validates :name, presence: true, on: :create
  validates :address, presence: true, on: :create
  validates :user_id, presence: true, on: :create
  validates :property_type,
            inclusion: { in: Property::PROPERTY_TYPES },
            on: [:create, :update],
            allow_blank: true
  validates :condition,
            inclusion: { in: Property::CONDITIONS },
            on: [:create, :update],
            allow_blank: true
  validate :facilities_supported, on: [:create, :update]

  def self.from_create_params(params)
    new(
      name: params[:name],
      description: params[:description],
      address: params[:address],
      property_type: params[:property_type],
      condition: params[:condition],
      facilities: params[:facilities],
      user_id: params[:user_id],
      rules: params[:rules],
      roomphotos: params[:roomphotos] || params[:photos],
      photos: params[:photos],
    )
  end

  def self.from_update_params(params)
    new(
      name: params[:name],
      description: params[:description],
      address: params[:address],
      property_type: params[:property_type],
      condition: params[:condition],
      facilities: params[:facilities],
      user_id: params[:user_id],
      rules: params[:rules],
      roomphotos: params[:roomphotos] || params[:photos],
      photos: params[:photos],
    )
  end

  def self.from_filter_params(params)
    new(
      property_type: params[:property_type],
      condition: params[:condition],
      search: params[:search],
      sort: params[:sort],
      page: params[:page],
      per_page: params[:per_page],
      status: params[:status],
      unit_type: params[:unit_type],
      priority: params[:priority],
    )
  end

  def to_create_h
    {
      name: name,
      description: description,
      address: address,
      property_type: property_type,
      condition: condition,
      rules: rules,
      facilities: normalize_facilities,
      user_id: user_id,
      roomphotos: normalize_roomphotos,
    }
  end

  def to_update_h
    {
      name: name,
      description: description,
      address: address,
      property_type: property_type,
      condition: condition,
      rules: rules,
      facilities: normalize_facilities,
      user_id: user_id,
      roomphotos: normalize_roomphotos,
    }.compact
  end

  def to_filter_h(default_per_page:)
    {
      property_type: property_type,
      condition: condition,
      search: search,
      sort: sort,
      page: (page.presence || 1).to_i,
      per_page: [(per_page.presence || default_per_page).to_i, 100].min,
      status: status,
      unit_type: unit_type,
      priority: priority,
    }.compact
  end

  private

  def facilities_supported
    values = normalize_facilities
    return if values.blank?
    return if values.all? { |value| Property::AVAILABLE_FACILITIES.include?(value) }

    errors.add(:facilities, "contains unsupported values")
  end

  def normalize_facilities
    case facilities
    when Array
      facilities.reject(&:blank?)
    when String
      facilities.split(",").map(&:strip).reject(&:blank?)
    else
      []
    end
  end

  def normalize_roomphotos
    raw_value = roomphotos.presence || photos
    return [] unless raw_value.present?
    return raw_value.reject(&:blank?) if raw_value.is_a?(Array)

    [raw_value].reject(&:blank?)
  end
end
