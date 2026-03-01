# frozen_string_literal: true

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
    current_user&.admin?
  end

  def create?
    current_user&.admin?
  end

  def update?
    current_user&.admin?
  end

  def destroy?
    current_user&.admin?
  end
end
