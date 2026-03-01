# frozen_string_literal: true

module Users
  class BaseUsersService
    include BaseService

    def initialize(current_user:, params: {})
      @current_user = current_user
      @params = params
    end

    private

    def ensure_admin!
      return if @current_user&.admin?

      raise Pundit::NotAuthorizedError, "Only admin can manage users"
    end

    def normalize_role(value)
      return nil if value.nil?

      map = {
        "owner" => "owner",
        "admin" => "admin",
        "tenant" => "tenant",
        "0" => "owner",
        "1" => "admin",
        "2" => "tenant",
        0 => "owner",
        1 => "admin",
        2 => "tenant",
      }

      map[value]
    end

    def normalize_account_status(value)
      return nil if value.nil?

      map = {
        "active" => "active",
        "inactive" => "inactive",
        "0" => "active",
        "1" => "inactive",
        0 => "active",
        1 => "inactive",
      }

      map[value]
    end
  end
end
