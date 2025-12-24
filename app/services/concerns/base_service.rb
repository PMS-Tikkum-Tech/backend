# frozen_string_literal: true

require 'ostruct'

# Base Service module for all services
# Provides standard success/failure response pattern
module BaseService
  extend ActiveSupport::Concern

  # Return successful response with data and message
  def success(data, message = 'Operation successful')
    OpenStruct.new(success?: true, data: data, message: message)
  end

  # Return failed response with errors and message
  def failure(errors, message = 'Operation failed')
    error_list = errors.is_a?(Array) ? errors : [errors]
    OpenStruct.new(success?: false, errors: error_list,
                   message: message)
  end

  # Execute block within database transaction
  def with_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  rescue StandardError => e
    failure([e.message], 'Transaction failed')
  end
end
