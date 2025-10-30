
class Whatsapp::Dispatch::WhatsappWebService < ApplicationJob
  queue_as :medium

  def perform(user, contact, inbox, campaign, message)
    Messages::MessageBuilder.new(user, get_last_conversation(contact, inbox), {
        content: message,
        message_type: 'outgoing',
        additional_attributes: { campaign_id: campaign.id }
    }).perform
  end  

  def get_last_conversation(contact, inbox)
    contact_inbox = contact.contact_inboxes.find_or_create_by!(inbox_id: inbox.id) do |ci|
       ci.source_id  = contact.phone_number.delete('+').to_s
    end
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
end