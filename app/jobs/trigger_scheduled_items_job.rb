class TriggerScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  BATCH_CAMPAIGN = 100
  BATCH_INBOX    = 100

  def perform
    # trigger the scheduled campaign jobs
    Campaign.where(campaign_type: :one_off,
                   campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.find_each(batch_size: BATCH_CAMPAIGN) do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end

    # Job Remarketing
    Inbox.joins(:agent_bot)
    .where(enabled_remarketing: true)
    .where.not(agent_bots: { outgoing_url: [nil, ""] })
    .where.not(time_wait_last_message: [nil])
    .where.not(unit_time: [nil])
    .find_each(batch_size: BATCH_INBOX) do |inbox|
      RemarketingJob.perform_later(inbox)
    end

    # Job to reopen snoozed conversations
    Conversations::ReopenSnoozedConversationsJob.perform_later

    # Job to reopen snoozed notifications
    Notification::ReopenSnoozedNotificationsJob.perform_later

    # Job to auto-resolve conversations
    Account::ConversationsResolutionSchedulerJob.perform_later

    # Job to sync whatsapp templates
    Channels::Whatsapp::TemplatesSyncSchedulerJob.perform_later

    # Job to clear notifications which are older than 1 month
    Notification::RemoveOldNotificationJob.perform_later
  end
end

TriggerScheduledItemsJob.prepend_mod_with('TriggerScheduledItemsJob')
