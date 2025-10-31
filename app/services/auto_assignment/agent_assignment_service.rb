class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    round_robin_manage_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  def perform
    new_assignee = find_assignee
    if new_assignee
      conversation.update(assignee: new_assignee)
      agent = new_assignee
      inbox = Inbox.find(conversation.inbox_id)
      Rails.logger.info "> ----------- AUTOASIGNACION EJECUTADA::agent_assignment_service.rb/perform --------------- <"
      Rails.logger.info "DATOS DE LA CONVERSACION: #{conversation.inspect}"
      Rails.logger.info "DATOS DEL AGENTE ASIGNADO: #{agent.inspect}"
      Rails.logger.info "DATOS DEL INBOX: #{inbox.inspect}"

      
      # conversation_db = Conversation.find(conversation.id)
      conversation.reload
      
      agent_name = agent.name
      inbox_id = inbox&.notification_inbox_id
      conversation_id = conversation&.display_id
      to_phone = agent&.phone_number.to_s.strip
      to_phone = "+#{to_phone}" unless to_phone.blank? || to_phone.start_with?('+')
      base = ENV.fetch('FRONTEND_URL', '')

      Rails.logger.info "[inbox_id]: #{inbox_id.inspect}"
      Rails.logger.info "[to_phone]: #{to_phone.inspect}"
      Rails.logger.info "[current_user]: #{conversation.account_id.inspect}"

      if inbox_id.present? && to_phone.present?
        Notification::PushNotificationAgentJob.perform_later(
          inbox_id: inbox_id, # Inbox de WhatsApp
          to_phone: to_phone, # Numero de destino (ej: +59171234567)
          text: "Hola #{agent_name}. Se te asigno una nueva conversación, puedes verla aquí:\n#{base}/app/accounts/#{conversation.account_id}/conversations/#{conversation_id}",
          sender_user_id: conversation.account_id # Id de usuario (opcional)
        )
        Rails.logger.info("[WhatsApp] Se envio la notificacion por mensaje: inbox_id=#{inbox_id.inspect}, phone=#{to_phone.inspect}")
      else
        Rails.logger.warn("[WhatsApp] No se pudo enviar el mensaje: inbox_id=#{inbox_id.inspect}, phone=#{to_phone.inspect}")
      end
    end
  end


  private

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    # @allowed_online_agent_ids ||= online_agent_ids & allowed_agent_ids&.map(&:to_s)
    # removing the online-only filter
    allowed_agent_ids&.map(&:to_s)
  end

  def round_robin_manage_service

    @round_robin_manage_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  end
end
