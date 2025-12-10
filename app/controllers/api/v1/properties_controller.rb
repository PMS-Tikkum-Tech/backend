# frozen_string_literal: true

# Controller Layer (Interface/Authorization)
# Fokus: Cek izin, ambil params, delegasi ke Service, render via Presenter

class Api::V1::PropertiesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :update, :destroy]

  # GET /api/v1/properties
  def index
    # 1. Input/DTO - Normalisasi dan validasi params
    input = PropertySearchInput.from_params(search_params, current_user)

    unless input.valid?
      return render_error('Invalid search parameters', input.errors, :unprocessable_entity)
    end

    # 2. Service/Use Case - Business logic dengan eager loading
    result = PropertyService.new(current_user: current_user, filters: input.to_h).search

    if result.success?
      # 3. Presenter/Output - Mapping response tanpa query
      presented_data = PropertyPresenter::SearchResult.from_collection(result.data, current_user)
      render_success('Properties retrieved successfully', presented_data)
    else
      render_error(result.message, result.errors, :unprocessable_entity)
    end
  end

  # GET /api/v1/properties/:id
  def show
    authorize @property, class: PropertyPolicy

    # 1. Service - Get property dengan calculated data
    result = PropertyService.new(property: @property, current_user: current_user).show

    if result.success?
      # 2. Presenter - Format response
      presented_data = PropertyPresenter::Detail.new(result.data, current_user).to_hash
      render_success('Property retrieved successfully', presented_data)
    else
      render_error(result.message, result.errors, :not_found)
    end
  end

  # POST /api/v1/properties
  def create
    # 1. Input/DTO - Validasi params
    input = PropertyInput.from_params(property_params, current_user)

    unless input.valid?
      return render_error('Invalid property data', input.errors, :unprocessable_entity)
    end

    # 2. Authorization check
    authorize Property, class: PropertyPolicy

    # 3. Service - Create property
    result = PropertyService.new(current_user: current_user).create(input.to_property_params)

    if result.success?
      # 4. Presenter - Format response
      presented_data = PropertyPresenter::Detail.new(result.data, current_user).to_hash
      render_success('Property created successfully', presented_data, :created)
    else
      render_error(result.message, result.errors, :unprocessable_entity)
    end
  end

  # PUT /api/v1/properties/:id
  def update
    authorize @property, class: PropertyPolicy

    # 1. Input/DTO - Validasi params
    input = PropertyInput.from_params(property_params, current_user)

    unless input.valid?
      return render_error('Invalid property data', input.errors, :unprocessable_entity)
    end

    # 2. Service - Update property
    result = PropertyService.new(property: @property, current_user: current_user)
                           .update(input.to_property_params)

    if result.success?
      # 3. Presenter - Format response
      presented_data = PropertyPresenter::Detail.new(result.data, current_user).to_hash
      render_success('Property updated successfully', presented_data)
    else
      render_error(result.message, result.errors, :unprocessable_entity)
    end
  end

  # DELETE /api/v1/properties/:id
  def destroy
    authorize @property, class: PropertyPolicy

    # 1. Service - Delete property
    result = PropertyService.new(property: @property, current_user: current_user).destroy

    if result.success?
      render_success('Property deleted successfully', nil, :no_content)
    else
      render_error(result.message, result.errors, :unprocessable_entity)
    end
  end

  # GET /api/v1/properties/:id/statistics
  def statistics
    authorize @property, class: PropertyPolicy

    # 1. Service - Get statistics
    result = PropertyService.new(property: @property, current_user: current_user).statistics

    if result.success?
      render_success('Statistics retrieved successfully', result.data)
    else
      render_error(result.message, result.errors, :unprocessable_entity)
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Property not found', nil, :not_found)
  end

  def property_params
    params.require(:property).permit(
      :title,
      :description,
      :address,
      :city,
      :province,
      :postal_code,
      :country,
      :property_type,
      :accommodation_type,
      :status,
      :latitude,
      :longitude,
      amenity_ids: []
    )
  end

  def search_params
    params.permit(
      :property_type,
      :accommodation_type,
      :city,
      :min_price,
      :max_price,
      :page,
      :per_page
    )
  end
end

# Input class untuk search parameters
class PropertySearchInput
  include BaseInput

  attribute :property_type, :string
  attribute :accommodation_type, :string
  attribute :city, :string
  attribute :min_price, :float
  attribute :max_price, :float
  attribute :page, :integer, default: 1
  attribute :per_page, :integer, default: 20

  validate :validate_property_type
  validate :validate_accommodation_type
  validate :validate_price_range
  validate :validate_pagination

  def to_h
    attributes.except(:page, :per_page)
  end

  private

  def validate_property_type
    return true if property_type.blank?

    allowed_types = %w(kos apartment house villa)
    unless allowed_types.include?(property_type)
      errors.add(:property_type, "must be one of: #{allowed_types.join(', ')}")
    end
  end

  def validate_accommodation_type
    return true if accommodation_type.blank?

    allowed_types = %w(male female mixed)
    unless allowed_types.include?(accommodation_type)
      errors.add(:accommodation_type, "must be one of: #{allowed_types.join(', ')}")
    end
  end

  def validate_price_range
    return true if min_price.blank? && max_price.blank?

    if min_price.present? && !min_price.positive?
      errors.add(:min_price, "must be greater than 0")
    end

    if max_price.present? && !max_price.positive?
      errors.add(:max_price, "must be greater than 0")
    end

    if min_price.present? && max_price.present? && min_price > max_price
      errors.add(:max_price, "must be greater than min_price")
    end
  end

  def validate_pagination
    unless page.positive?
      errors.add(:page, "must be greater than 0")
    end

    unless (1..100).include?(per_page)
      errors.add(:per_page, "must be between 1 and 100")
    end
  end
end