# frozen_string_literal: true

module Properties
  class BasePropertiesService
    include BaseService

    def initialize(current_user:, params: {})
      @current_user = current_user
      @params = params
    end

    private

    def ensure_admin!
      return if @current_user&.admin?

      raise Pundit::NotAuthorizedError, "Only admin can manage properties"
    end

    def apply_created_sort(scope, sort)
      case sort
      when "oldest"
        scope.order(created_at: :asc)
      else
        scope.order(created_at: :desc)
      end
    end
  end
end
