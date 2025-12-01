
class Whatsapp::Dispatch::WhatsappService < ApplicationJob
  queue_as :medium

  def perform(user, contact, inbox, campaign, file, url)
    Messages::MessageBuilder.new(user, get_last_conversation(contact, inbox), {
        content: interpolate_message(campaign.message, contact, campaign.additional_attributes),
        message_type: 'outgoing',
        additional_attributes: {
          template_params: generate_template_whatsapp(contact, url, campaign.additional_attributes),
          campaign_id: campaign.id,
        },
        attachments: attachments(file)
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

  def interpolate_message(message, contact, additional_attributes)
    additional_attributes.dig("template_params","processed_params").each do |key, value|
      if value["type"] == "dinamic"
        interpolate = contact.try(value["content"]) || value["content"]
        message = message.gsub(value["content"], interpolate.to_s)
      end
    end
    message
  end

  def generate_template_whatsapp(contact, url, additional_attributes)
    params = additional_attributes["template_params"] || {}
    template_whatsapp = {
        "name" => params.dig("name"),
        "category" => params.dig("category"),
        "language" => params.dig("language"),
        "processed_params" => resolve_contact_parameters(contact, params.dig("processed_params"))
    }
    if params.dig("header").present?
      template_whatsapp["header"] = {
        "url" => url,
        "format" => params.dig("header","format")
      }
    end
    template_whatsapp
  end

  def resolve_contact_parameters(contact, params)
    params.each_with_object({}) do |(key, value), acc|
      if value["type"] == "static"
        acc[key] = value["content"]
      else
        acc[key] = contact.try(value["content"]) || value["content"]
      end
    end
  end

  def attachments(blob)
    return nil unless blob
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(blob.download)
    tempfile.rewind
    [
      ActionDispatch::Http::UploadedFile.new(
        filename: blob.filename.to_s,
        type: blob.content_type,
        tempfile: tempfile
      )
    ]
  end

end