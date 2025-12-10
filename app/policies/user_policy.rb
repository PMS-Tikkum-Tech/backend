# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # Users can view their own profile
  def show?
    owner? || admin?
  end

  # Users can update their own profile
  def update?
    owner? || admin?
  end

  # Users can edit their own profile
  def edit?
    update?
  end

  # Only admins can delete users
  def destroy?
    admin?
  end

  # Admins can list all users, others see empty
  def index?
    admin?
  end

  # Users can create new accounts (registration handled elsewhere)
  def create?
    false # Registration is handled by devise_token_auth
  end

  # Only admins can create users directly
  def new?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      else
        scope.where(id: user.id) # Users can only see themselves
      end
    end
  end
end