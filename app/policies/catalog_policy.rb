# app/policies/catalog_policy.rb
class CatalogPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = true
  def update?  = true
  def destroy? = true

  alias bulk_create?  create?
  alias bulk_destroy? destroy?

  class Scope < Scope
    def resolve
      scope.where(account_id: @account.id)
    end
  end
end
