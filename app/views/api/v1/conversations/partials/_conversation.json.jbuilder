# TODO: Move this into models jbuilder
# Currently the file there is used only for search endpoint.
# Everywhere else we use conversation builder in partials folder

json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assignee&.account
    json.assignee do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assignee
    end
  end
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
    end
  end
  json.hmac_verified conversation.contact_inbox&.hmac_verified
end
json.kanban_state do
  if conversation.kanban_states_id
    kanban_state = KanbanState.find(conversation.kanban_states_id)
    json.id kanban_state.id
    json.name kanban_state.name
    json.color kanban_state.color
    json.order kanban_state.order
  else
    json.id nil
    json.name nil
    json.color nil
    json.order nil
  end
end
json.score conversation.score
json.justification conversation.justification
json.conversation_sentiment_id conversation.conversation_sentiment_id
json.last_sentiment_analysis conversation.last_sentiment_analysis.to_i
json.active_agent_bot conversation.active_agent_bot
json.enabled_remarketing conversation.enabled_remarketing
json.conversations_state_name conversation.conversation_state&.name
json.conversations_state do 
  if conversation.conversations_state_id
    state = ConversationState.find(conversation.conversations_state_id)
    json.name state.name
    json.description state.description
    json.color state.color
  else
    json.name nil
    json.description nil
    json.color nil
  end
end
json.id conversation.display_id
if conversation.messages.where(account_id: conversation.account_id).last.blank?
  json.messages []
else
  json.messages [
    conversation.messages.where(account_id: conversation.account_id)
                .includes([{ attachments: [{ file_attachment: [:blob] }] }]).last.try(:push_event_data)
  ]
end

json.account_id conversation.account_id
json.uuid conversation.uuid
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.assignee_last_seen_at conversation.assignee_last_seen_at.to_i
json.can_reply conversation.can_reply?
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.custom_attributes conversation.custom_attributes
json.inbox_id conversation.inbox_id
json.labels conversation.cached_label_list_array
json.muted conversation.muted?
json.snoozed_until conversation.snoozed_until
json.status conversation.status
json.created_at conversation.created_at.to_i
json.timestamp conversation.last_activity_at.to_i
json.first_reply_created_at conversation.first_reply_created_at.to_i
json.unread_count conversation.unread_incoming_messages.count
json.last_non_activity_message conversation.messages.where(account_id: conversation.account_id).non_activity_messages.first.try(:push_event_data)
json.last_activity_at conversation.last_activity_at.to_i
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
json.sla_policy_id conversation.sla_policy_id
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
