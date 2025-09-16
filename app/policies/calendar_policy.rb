class CalendarPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = true
  def update?  = true
  def destroy? = true

  class Scope < Scope
    def resolve
      scope.where(account_id: @account.id)
    end
  end
end
