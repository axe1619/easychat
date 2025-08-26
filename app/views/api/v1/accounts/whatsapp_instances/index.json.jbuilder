json.payload do
  json.array! @whatsapp_instances do |instance|
    json.id instance.id
    json.instance_name instance.instance_name
    json.chatwoot_account_id instance.chatwoot_account_id
    json.chatwoot_url instance.chatwoot_url
    json.chatwoot_sign_msg instance.chatwoot_sign_msg
    json.chatwoot_reopen_conversation instance.chatwoot_reopen_conversation
    json.chatwoot_conversation_pending instance.chatwoot_conversation_pending
    json.sign_delimiter instance.sign_delimiter
    json.import_contacts instance.import_contacts
    json.import_messages instance.import_messages
    json.days_limit_import_messages instance.days_limit_import_messages
    json.auto_create instance.auto_create
    json.webhook_url instance.webhook_url
  end
end
