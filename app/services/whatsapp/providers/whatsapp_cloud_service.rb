class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  CALLS_API_VERSION = ENV.fetch('WHATSAPP_CLOUD_CALLS_API_VERSION', 'v20.0')
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        template: template_body_parameters(template_info),
        type: 'template'
      }.to_json
    )

    process_response(response)
  end

  def sync_templates
    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url)
    return [] unless response.success?

    next_url = next_url(response)

    return response['data'] + fetch_whatsapp_templates(next_url) if next_url.present?

    response['data']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    response = HTTParty.get("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    response.success?
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def calls_settings_path
    "#{api_base_path}/#{CALLS_API_VERSION}/#{whatsapp_channel.provider_config['phone_number_id']}/settings"
  end

  def calls_path
    "#{api_base_path}/#{CALLS_API_VERSION}/#{whatsapp_channel.provider_config['phone_number_id']}/calls"
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        to: phone_number,
        text: { body: message.content },
        type: 'text'
      }.to_json
    )

    process_response(response)
  end

  def send_call_permission_request(to:, body: nil)
    payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: to,
      type: 'interactive',
      interactive: {
        type: 'call_permission_request',
        action: { name: 'call_permission_request' }
      }
    }
    payload[:interactive][:body] = { text: body } if body.present?

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: payload.to_json
    )

    process_response(response)
  end

  def fetch_call_permission(user_wa_id)
    response = HTTParty.get(
      "#{api_base_path}/#{CALLS_API_VERSION}/#{whatsapp_channel.provider_config['phone_number_id']}/call_permissions",
      headers: api_headers,
      query: { user_wa_id: user_wa_id }
    )
    settings_response(response)
  end

  def initiate_call(to:, sdp:, sdp_type: 'offer', biz_opaque_callback_data: nil, action: 'connect')
    payload = {
      messaging_product: 'whatsapp',
      to: to,
      action: action,
      session: {
        sdp_type: sdp_type,
        sdp: sdp
      }
    }
    payload[:biz_opaque_callback_data] = biz_opaque_callback_data if biz_opaque_callback_data.present?

    response = HTTParty.post(
      calls_path,
      headers: api_headers,
      body: payload.to_json
    )

    return response['calls'].first['id'] if response.success? && response['calls'].present?

    Rails.logger.error "WhatsApp initiate call error: #{response.code} - #{response.body}"
    nil
  end

  def terminate_call(call_id:, action: 'terminate')
    payload = {
      messaging_product: 'whatsapp',
      call_id: call_id,
      action: action
    }

    response = HTTParty.post(
      calls_path,
      headers: api_headers,
      body: payload.to_json
    )

    return true if response.success?

    Rails.logger.error "WhatsApp terminate call error: #{response.code} - #{response.body}"
    false
  end

  def fetch_call_settings(include_sip_credentials: false)
    query = include_sip_credentials ? '?include_sip_credentials=true' : ''
    response = HTTParty.get("#{calls_settings_path}#{query}", headers: api_headers)
    settings_response(response)
  end

  # calling_params should match the "calling" object in the Meta docs
  def update_call_settings(calling_params)
    response = HTTParty.post(
      calls_settings_path,
      headers: api_headers,
      body: { calling: calling_params }.to_json
    )
    settings_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response)
  end

  def process_response(response)
    if response.success?
      response['messages'].first['id']
    else
      Rails.logger.error response.body
      nil
    end
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      },
      components: template_component( template_info[:header], template_info[:parameters] )
    }
  end

  def template_component(header, parameters)
    components = [{ type: 'body', parameters: parameters }]
    return components unless header.present?
    format_type = header["format"].downcase
    components << {
        type: "header",
        parameters: [{ 
          type: format_type, 
          format_type.to_sym => { link: header["url"] } 
        }]
    }
    components
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response)
  end

  private

  def settings_response(response)
    return response.parsed_response if response.success?

    Rails.logger.error "WhatsApp call settings error: #{response.code} - #{response.body}"
    nil
  end
end
