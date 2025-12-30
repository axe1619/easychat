class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def limit_status?
    @account_user.administrator?
  end

  def bulk_create?
    @account_user.administrator?
  end
end
