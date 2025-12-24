# frozen_string_literal: true

# Base Presenter module for all presenters
# Provides common formatting and collection methods
module BasePresenter
  extend ActiveSupport::Concern

  # Format currency value (for future use)
  def format_currency(value)
    return nil unless value

    format('%.2f', value)
  end

  # Format datetime to ISO8601 string
  def format_datetime(datetime)
    return nil unless datetime

    datetime.iso8601
  end

  # Class method to transform collection
  module ClassMethods
    def from_collection(collection, current_user = nil)
      collection.map { |item| new(item, current_user).as_json }
    end
  end
end
