class Notification::PushNotificationAgentJob < ApplicationJob
  queue_as :default

  # Uso recomendado:
  # Notification::PushNotificationAgentJob.perform_later(
  #   inbox_id:        123,                 # Inbox WhatsApp
  #   to_phone:        '+59171234567',      # E.164
  #   text:            'Hola se te asigno una conversacion...',
  #   sender_user_id:  8                    # (opcional) el User que envía
  # )
  def perform(inbox_id:, to_phone:, text:, sender_user_id: nil)
    inbox = Inbox.find_by(id: inbox_id)
    raise ArgumentError, 'Inbox no encontrado' unless inbox

    to_phone = normalize_phone(to_phone)
    user     = sender_user_id ? User.find_by(id: sender_user_id) : default_sender_for(inbox)
    raise ArgumentError, 'No hay usuario remitente' unless user

    conversation = find_or_open_conversation(inbox, to_phone)

    Messages::MessageBuilder.new(
      user,
      conversation,
      {
        content: text.to_s.strip,
        message_type: 'outgoing',
        message_sub_type: 'notification'
      }
    ).perform

    Rails.logger.info("[PushNotificationAgentJob] Enviado WhatsApp a #{to_phone} en inbox #{inbox.id}, conv #{conversation.display_id}")
  end

  private


  def default_sender_for(inbox)
    # Elige el primer usuario del account (ajústalo a tu lógica)
    inbox.account.users.order(:id).first
  end

  def normalize_phone(phone)
    p = phone.to_s.strip
    p.start_with?('+') ? p : "+#{p}"
  end

  # Abre o reutiliza una conversación con ese contacto en el inbox
  def find_or_open_conversation(inbox, phone_e164)
    contact       = find_or_create_contact(inbox.account_id, phone_e164)
    contact_inbox = find_or_create_contact_inbox(contact, inbox.id)

    if inbox.lock_to_single_conversation
      contact_inbox.conversations.last || create_conversation(inbox, contact, contact_inbox)
    else
      contact_inbox.conversations.where.not(status: :resolved).last ||
        create_conversation(inbox, contact, contact_inbox)
    end
  end

  def find_or_create_contact(account_id, phone_e164)
    Contact.find_or_create_by!(phone_number: phone_e164) do |c|
      c.account_id   = account_id
      c.name         = phone_e164
      c.phone_number = phone_e164
    end
  end

  def find_or_create_contact_inbox(contact, inbox_id)
    contact.contact_inboxes.find_or_create_by!(inbox_id: inbox_id) do |ci|
      # source_id suele ser el número sin '+'
      ci.source_id = contact.phone_number.delete('+')
    end
  end

  def create_conversation(inbox, contact, contact_inbox)
    ::Conversation.create!(
      account_id:        inbox.account_id,
      inbox_id:          inbox.id,
      contact_id:        contact.id,
      contact_inbox_id:  contact_inbox.id
    )
  end
end




#?Codigo antiguo

# class Notification::PushNotificationAgentJob < ApplicationJob
#   queue_as :default

#   def perform(conversation)

#     agent_assignee_id = conversation.assignee_id
#     notification = state[:notification]
#     phones       = conversation.assignee_id # Numero de agente
#     user         = user(notification["sender_id"]) #Usuario que envia el mensaje
#     inbox        = inbox(conversation.notification_inbox_id)
    
#     conversation_notify = last_conversation(inbox)
#     Messages::MessageBuilder.new(user, conversation_notify, {
#         content: template_message(conversation_analyzed, state).strip,
#         message_type: 'outgoing',
#         message_sub_type: 'notification'
#     }).perform
    
#   end

#   def user(sender_id)
#     User.find_by(id: sender_id)
#   end

#   def inbox(id)
#     Inbox.find_by(id: id)
#   end

#   def contact(account_id, phone)
#     Contact.find_or_create_by!(phone_number: phone) do |contact|
#       contact.account_id   = account_id
#       contact.name         = phone
#       contact.phone_number = phone
#     end
#   end

#   def contact_inbox(contact, inbox_id)
#     contact.contact_inboxes.find_or_create_by!(inbox_id: inbox_id) do |ci|
#        ci.source_id  = contact.phone_number.delete('+').to_s
#     end
#   end

#   def last_conversation(inbox, phone)
#     contact       = contact(inbox.account_id, phone)
#     contact_inbox = contact_inbox(contact, inbox.id)
#     conversation_last_open = if inbox.lock_to_single_conversation
#                                   contact_inbox.conversations.last
#                               else
#                                   contact_inbox.conversations.where.not(status: :resolved).last
#                               end
#     return conversation_last_open if conversation_last_open
#     ::Conversation.create!({
#         account_id: inbox.account_id,
#         inbox_id: inbox.id,
#         contact_id: contact.id,
#         contact_inbox_id: contact_inbox.id
#     })
#   end

#   def template_message(conversation, state)
#     <<~MSG
#       *Channel*      : #{conversation.inbox.name} (#{conversation.inbox.channel_type.sub("Channel::", "")})
#       *Notification* : #{state.name}
#       *Link*         : https://easycontact.top/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}
#     MSG
#   end

# end