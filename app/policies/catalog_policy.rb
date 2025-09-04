class CatalogPolicy < ApplicationPolicy
  def index?   = @account_user.present?
  def show?    = @account_user.present?
  def create?  = true
  def update?  = true
  def destroy? = true

  class Scope < Scope
    def resolve
      scope.where(account_id: @account.id)
    end
  end
end
