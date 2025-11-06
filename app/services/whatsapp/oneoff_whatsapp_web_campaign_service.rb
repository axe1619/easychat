require 'open-uri'
require 'tempfile'
class Whatsapp::OneoffWhatsappWebCampaignService
  pattr_initialize [:campaign!]

  # congested queue
  MAX_LATENCY_JOB = 5.seconds
  BATCH = 100

  def perform
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
    option_messages = campaign.additional_attributes["messages"].cycle
    contacts    = campaign.account.contacts.tagged_with(audience_labels, any: true).where.not(phone_number: [nil, ""])
    user        = User.find_by(id: campaign.sender_id)
    inbox       = Inbox.find_by(id: campaign.inbox_id)
    start_time_campaign = Time.now
    reach_campaign = 0
    return if user.blank? || inbox.blank?
    delay = 0
    delay_queue = 0
    contacts.find_in_batches(batch_size: BATCH) do |batch|
      batch.each_with_index do |contact, index|
        analyze_queue  = (index % 20 == 0)
        message = option_messages.next  # round robin
        delay = rand(8..20)
        if analyze_queue && queue_congested?("medium", MAX_LATENCY_JOB)
          Whatsapp::Dispatch::WhatsappWebService.perform_now(user, contact, inbox, campaign, message)
          sleep(delay)
          delay_queue = [delay_queue - delay, 0].max
        else
          delay_queue += delay
          Whatsapp::Dispatch::WhatsappWebService.set(wait: delay_queue.seconds).perform_later(user, contact, inbox, campaign, message)
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

  def queue_congested?(name, max_latency)
    queue = Sidekiq::Queue.new(name)
    congested = queue.latency > max_latency
    Rails.logger.info "QUEUE_CONGESTED: size:#{queue.size}, latency:#{queue.latency}" if congested
    congested
  end
end
