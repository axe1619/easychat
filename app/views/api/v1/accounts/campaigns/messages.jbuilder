json.array! @messages do |message|
  json.id message.id
  json.content message.content
  json.account_id message.account_id
  json.inbox_id message.inbox_id
  json.conversation_id message.conversation_id
  json.message_type message.message_type
  json.created_at message.created_at
  json.updated_at message.updated_at
  json.status message.status
  json.source_id message.source_id
  json.content_type message.content_type
  json.content_attributes message.content_attributes
  json.sender_type message.sender_type
  json.sender_id message.sender_id
  json.contact_id message.contact_id
  json.contact_name message.contact_name
  json.contact_phone_number message.contact_phone_number
end

