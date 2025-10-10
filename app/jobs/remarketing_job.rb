class RemarketingJob < ApplicationJob
  queue_as :medium

  # (Unix Epoch Start)
  UNIX_EPOCH_START = Time.utc(1970, 1, 1, 0, 0, 0)
  URL_AGENT_REMARKETING = ENV.fetch('URL_AGENT_REMARKETING','')
  BATCH_CONVERSATION = 100
  UNITS = {
    0 => :minutes,
    1 => :hours
  }.freeze

  def perform(inbox)
    date_time_wait_last_message = inbox.time_wait_last_message.public_send(UNITS[inbox.unit_time]).ago
    query = inbox.conversations
            .where(status: [:open, :pending])
            .where(enabled_remarketing: true)
            .where.not(last_activity_outgoing_at: nil)
            .where("last_activity_outgoing_at > COALESCE(last_activity_incoming_at, ?)", UNIX_EPOCH_START)
            .where(last_activity_outgoing_at: 24.hours.ago..date_time_wait_last_message)
            
    query.find_each(batch_size: BATCH_CONVERSATION) do |conversation|
      if conversation.exceeded_remarketing_attempts(inbox.cout_max_remarketing_message)
        conversation.update!(enabled_remarketing: false, last_remarketing_closed: Time.now)
        return
      end
      # 50 request/seconds
      AgentBots::WebhookJob
      .set(wait: 0.02.seconds) 
      .perform_later(URL_AGENT_REMARKETING, generate_message_remarketing(inbox, conversation))
    end
  end

  private
  
  def generate_message_remarketing(inbox,conversation)
    {
        account: conversation.account.webhook_data,
        additional_attributes: {},
        content_attributes: {},
        content_type: "text",
        content: "",
        active_agent_bot: conversation.active_agent_bot,
        conversation: conversation.webhook_data,
        created_at: Time.zone.now,
        id: nil,
        inbox: inbox.webhook_data,
        message_type: :outgoing,
        message_sub_type: :remarketing,
        private: false,
        sender: nil,
        source_id: nil,
        behavior_remarketing: inbox.behavior_remarketing,
        cout_max_remarketing_message: inbox.cout_max_remarketing_message
    }
  end
end
