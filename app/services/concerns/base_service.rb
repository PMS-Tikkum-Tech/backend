# frozen_string_literal: true

module BaseService
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveModel::Attributes
  end

  class_methods do
    def call(*args, &block)
      new(*args).call(&block)
    end
  end

  # Helper untuk eager loading
  def eager_load_associations(associations)
    associations.each { |assoc| send(assoc) }
  end

  private

  def success(data = nil, message = nil)
    OpenStruct.new(success?: true, data: data, message: message, errors: nil)
  end

  def failure(errors, message = nil)
    OpenStruct.new(success?: false, data: nil, message: message, errors: errors)
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  rescue StandardError => e
    Rails.logger.error "Transaction failed: #{e.message}"
    failure([e.message], "Transaction failed")
  end
end