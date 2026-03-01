# frozen_string_literal: true

module LogActivities
  class LogActivityService
    def self.log(admin:, action:, module_name:, description:)
      LogActivity.create!(
        admin: admin,
        action: action,
        module_name: module_name,
        description: description,
      )
    rescue StandardError => exception
      Rails.logger.error("Failed to write log activity: #{exception.message}")
      nil
    end
  end
end
