# frozen_string_literal: true

module Users
  class ListService < BaseUsersService
    def call
      ensure_admin!

      users = User.order(created_at: :desc)
      users = apply_search(users)
      users = apply_role_filter(users)
      users = apply_status_filter(users)

      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 10).to_i, 100].min
      paginated_users = users.page(page).per(per_page)

      success(
        data: {
          users: paginated_users,
          pagination: {
            current_page: paginated_users.current_page,
            total_pages: paginated_users.total_pages,
            total_count: paginated_users.total_count,
            per_page: paginated_users.limit_value,
          },
        },
        message: "Users retrieved successfully",
      )
    rescue Pundit::NotAuthorizedError => exception
      failure(errors: [exception.message], message: "Forbidden")
    rescue StandardError => exception
      failure(errors: [exception.message], message: "Failed to list users")
    end

    private

    def apply_search(scope)
      return scope unless @params[:search].present?

      term = "%#{@params[:search]}%"
      scope.where("full_name ILIKE ? OR email ILIKE ?", term, term)
    end

    def apply_role_filter(scope)
      return scope unless @params[:role].present?

      role = normalize_role(@params[:role])
      return scope.none unless role

      scope.where(role: User.roles.fetch(role))
    end

    def apply_status_filter(scope)
      return scope unless @params[:account_status].present?

      status = normalize_account_status(@params[:account_status])
      return scope.none unless status

      scope.where(account_status: User.account_statuses.fetch(status))
    end
  end
end
