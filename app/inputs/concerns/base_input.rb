# frozen_string_literal: true

module BaseInput
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Validations
  end

  def to_h
    instance_values.symbolize_keys.compact
  end
end
