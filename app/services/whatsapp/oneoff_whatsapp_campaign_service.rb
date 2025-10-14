require 'open-uri'
require 'tempfile'
class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  def perform
    # raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox


  def process_audience(audience_labels)
    contacts    = campaign.account.contacts.tagged_with(audience_labels, any: true)
    user        = User.find_by(id: campaign.sender_id)
    inbox       = Inbox.find_by(id: campaign.inbox_id)
    template_campaign = campaign.additional_attributes
    file_blob = ActiveStorage::Blob.find_by(key: template_campaign["template_params"]["header"]["url"]) if header_exists?(template_campaign)
    attachments = load_file_blob(file_blob) if header_exists?(template_campaign)
    file_url = generate_file_url(file_blob) if header_exists?(template_campaign)
    return if user.nil? || inbox.nil?
    start_time_campaign = Time.now
    contacts.each do |contact|
      next if contact.phone_number.blank?
      conversation = get_last_conversation(contact, inbox)
      message = Messages::MessageBuilder.new(user, conversation, {
        content: interpolate_message(contact, template_campaign["template_params"]["processed_params"], campaign.message),
        message_type: 'outgoing',
        additional_attributes: {
          template_params: generate_template(contact, file_url, template_campaign),
          campaign_id: campaign.id,
        },
        attachments: attachments
      }).perform
    end
    end_time_campaign = Time.now
    campaign.update_columns(
      reach: contacts.distinct.count,
      duration: (end_time_campaign - start_time_campaign).to_i
    )
  end

  def load_file_blob(file_blob)
    tempfile = Tempfile.new
    tempfile.binmode
    tempfile.write(file_blob.download)
    tempfile.rewind
    [
      ActionDispatch::Http::UploadedFile.new(
        filename: file_blob.filename.to_s,
        type: file_blob.content_type,
        tempfile: tempfile
      )
    ]
  end

  def get_last_conversation(contact, inbox)
    contact_inbox = contact.contact_inboxes.find_or_create_by!(inbox_id: inbox.id) do |ci|
       ci.contact_id = contact.id 
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

  def generate_template(contact, file_url, template_campaign)
    template_params = {
        "name" => template_campaign["template_params"]["name"],
        "category" => template_campaign["template_params"]["category"],
        "language" => template_campaign["template_params"]["language"],
        "processed_params" => process_parameters(contact, template_campaign["template_params"]["processed_params"])
    }
    if header_exists?(template_campaign)
      template_params["header"] = {
        "url" => file_url,
        "format" => template_campaign["template_params"]["header"]["format"]
      }
    end
    template_params
  end

  def interpolate_message(contact, params, content)
    params.each do |key, value|
      if value["type"] == "dinamic"
        interpolate = contact.try(value["content"]) || value["content"]
        content = content.gsub(key, interpolate.to_s)
      end
    end
    content
  end

  def process_parameters(contact, params)
    params.each_with_object({}) do |(key, value), acc|
      if value["type"] == "static"
        acc[key] = value["content"]
      else
        acc[key] = contact.try(value["content"]) || value["content"]
      end
    end
  end

  def header_exists?(template)
    template.dig("template_params", "header").present?
  end

  def generate_file_url(blob)
    ActiveStorage::Current.url_options ||= { host: ENV.fetch("FRONTEND_URL") }
    blob.url(expires_in: 1.day, disposition: "inline")
  end
end
