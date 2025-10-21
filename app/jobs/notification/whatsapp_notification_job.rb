class Notification::WhatsappNotificationJob < ApplicationJob
  queue_as :default

  def perform(conversation_analyzed, state)
    notification = state[:notification]
    phones       = notification["phones"]
    user         = user(notification["sender_id"])
    inbox        = inbox(notification["inbox_id"])
    phones.each do |phone|
      conversation_notify = last_conversation(inbox, "+#{phone}")
      Messages::MessageBuilder.new(user, conversation_notify, {
          content: template_message(conversation_analyzed, state).strip,
          message_type: 'outgoing',
          message_sub_type: 'notification'
      }).perform
    end
  end

  def user(sender_id)
    User.find_by(id: sender_id)
  end

  def inbox(id)
    Inbox.find_by(id: id)
  end

  def contact(account_id, phone)
    Contact.find_or_create_by!(phone_number: phone) do |contact|
      contact.account_id   = account_id
      contact.name         = phone
      contact.phone_number = phone
    end
  end

  def contact_inbox(contact, inbox_id)
    contact.contact_inboxes.find_or_create_by!(inbox_id: inbox_id) do |ci|
       ci.source_id  = contact.phone_number.delete('+').to_s
    end
  end

  def last_conversation(inbox, phone)
    contact       = contact(inbox.account_id, phone)
    contact_inbox = contact_inbox(contact, inbox.id)
    conversation_last_open = if inbox.lock_to_single_conversation
                                  contact_inbox.conversations.last
                              else
                                  contact_inbox.conversations.where.not(status: :resolved).last
                              end
    return conversation_last_open if conversation_last_open
    ::Conversation.create!({
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id
    })
  end

  def template_message(conversation, state)
    <<~MSG
      *Channel*      : #{conversation.inbox.name} (#{conversation.inbox.channel_type.sub("Channel::", "")})
      *Notification* : #{state.name}
      *Link*         : https://easycontact.top/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}
    MSG
  end

end