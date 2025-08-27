class Conversations::EventDataPresenter < SimpleDelegator
  def push_data
    {
      additional_attributes: additional_attributes,
      active_agent_bot: active_agent_bot,
      enabled_remarketing: enabled_remarketing,
      can_reply: can_reply?,
      channel: inbox.try(:channel_type),
      contact_inbox: contact_inbox,
      id: display_id,
      kanban_state: build_kanban_state(kanban_state),
      inbox_id: inbox_id,
      messages: push_messages,
      labels: label_list,
      meta: push_meta,
      status: status,
      custom_attributes: custom_attributes,
      snoozed_until: snoozed_until,
      unread_count: unread_incoming_messages.count,
      first_reply_created_at: first_reply_created_at,
      priority: priority,
      waiting_since: waiting_since.to_i,
      **push_timestamps
    }
  end

  private

  def build_kanban_state(kanban)
    if kanban.nil?
      return {
        id: nil,
        name: nil,
        color: nil,
        order: nil
      }
    else
      return {
        id: kanban.id,
        name: kanban.name,
        color: kanban.color,
        order: kanban.order
      }
    end
  end

  def push_messages
    [messages.chat.last&.push_event_data].compact
  end

  def push_meta
    {
      sender: contact.push_event_data,
      assignee: assignee&.push_event_data,
      team: team&.push_event_data,
      hmac_verified: contact_inbox&.hmac_verified
    }
  end

  def push_timestamps
    {
      agent_last_seen_at: agent_last_seen_at.to_i,
      contact_last_seen_at: contact_last_seen_at.to_i,
      last_activity_at: last_activity_at.to_i,
      timestamp: last_activity_at.to_i,
      created_at: created_at.to_i
    }
  end
end
Conversations::EventDataPresenter.prepend_mod_with('Conversations::EventDataPresenter')
