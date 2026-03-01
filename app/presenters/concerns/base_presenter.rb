# frozen_string_literal: true

module BasePresenter
  private

  def format_datetime(value)
    value&.iso8601
  end
end
