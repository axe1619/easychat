class WhatsappInstancePolicy < ApplicationPolicy
  def index?; true; end
  def show?; true; end
  def create?; true; end
  def update?; true; end
  def destroy?; true; end
  def connect?; true; end
  def connection_state?; true; end
  def set_webhook?; true; end
end
