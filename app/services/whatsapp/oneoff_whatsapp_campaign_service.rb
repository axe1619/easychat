require 'open-uri'
require 'tempfile'
class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]
  
  # congested queue
  MAX_LATENCY_JOB = 5.seconds
  BATCH = 100

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
    contacts    = campaign.account.contacts.tagged_with(audience_labels, any: true).where.not(phone_number: [nil, ""])
    user        = User.find_by(id: campaign.sender_id)
    inbox       = Inbox.find_by(id: campaign.inbox_id)
    return if user.blank? || inbox.blank?
    file = load_file_campaign(campaign.additional_attributes)
    url  = generate_file_url(file)
    start_time_campaign = Time.now
    reach_campaign = 0
    contacts.find_in_batches(batch_size: BATCH) do |batch|
      batch.each_with_index do |contact, index|
        analyze_queue  = (index % 20 == 0)      
        if analyze_queue && queue_congested?("medium", MAX_LATENCY_JOB)
         Whatsapp::Dispatch::WhatsappService.perform_now(user, contact, inbox, campaign, file, url)
        else
         Whatsapp::Dispatch::WhatsappService.perform_later(user, contact, inbox, campaign, file, url)
        end
      end                                                                                                             
      reach_campaign += batch.size
    end
    end_time_campaign = Time.now
    campaign.update_columns(
      reach: reach_campaign,
      duration: (end_time_campaign - start_time_campaign).to_i
    )
  end

  def load_file_campaign(additional_attributes)
    key_storage = additional_attributes.dig("template_params", "header", "url")
    return nil if key_storage.blank?
    return ActiveStorage::Blob.find_by(key: key_storage)
  end

  def generate_file_url(blob)
    return nil unless blob
    ActiveStorage::Current.url_options ||= { host: ENV.fetch("FRONTEND_URL") }
    blob.url(expires_in: 1.day, disposition: "inline")
  end

  def queue_congested?(name, max_latency)
    queue = Sidekiq::Queue.new(name)
    congested = queue.latency > max_latency
    Rails.logger.info "WHATSAPP_BUSSINES_QUEUE_CONGESTED: size:#{queue.size}, latency:#{queue.latency}" if congested
    congested
  end

end
