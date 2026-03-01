# frozen_string_literal: true

require "ostruct"

module BaseService
  private

  def success(data: nil, message: "Operation successful")
    OpenStruct.new(
      success?: true,
      data: data,
      message: message,
    )
  end

  def failure(errors:, message: "Operation failed")
    normalized_errors = errors.is_a?(Array) ? errors : [errors]

    OpenStruct.new(
      success?: false,
      errors: normalized_errors,
      message: message,
    )
  end
end
