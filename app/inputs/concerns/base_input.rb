# frozen_string_literal: true

# Base Input module for all input DTOs
# Provides common validation and conversion methods
module BaseInput
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Validations
  end

  # Convert attributes to hash
  def to_h
    attributes.symbolize_keys.compact
  end
end
