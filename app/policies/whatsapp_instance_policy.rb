class WhatsappInstancePolicy < ApplicationPolicy
  def create? 
    true 
  end
  def connect?
     true
  end
  def state? 
    true
  end
  def set_webhook? 
    true
  end
  def sync_templates? 
    true
  end
end
