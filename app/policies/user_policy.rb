# frozen_string_literal: true

# UserPolicy for user authorization using Pundit
# Defines what actions each role can perform on users
class UserPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def index?
    current_user&.admin?
  end

  def show?
    current_user&.admin? || current_user&.id == user.id
  end

  def create?
    current_user&.admin?
  end

  def update?
    current_user&.admin? || current_user&.id == user.id
  end

  def destroy?
    current_user&.admin?
  end

  # Scope class for indexing users
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user = current_user
      @scope = scope
    end

    def resolve
      if current_user&.admin?
        scope.all
      elsif current_user
        scope.where(id: current_user.id)
      else
        scope.none
      end
    end
  end
end
