class Instagram::SendOnInstagramService < Instagram::BaseSendService
  private

  def channel_class
    Channel::Instagram
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    access_token = channel.access_token
    query = { access_token: access_token }
    instagram_id = channel.instagram_id.presence || 'me'

    Rails.logger.info(
      {
        service: 'Instagram::SendOnInstagramService',
        action: 'send_message',
        instagram_id: instagram_id,
        recipient_id: message_content.dig(:recipient, :id) || message_content.dig('recipient', 'id'),
        has_text: message_content.dig(:message, :text).present? || message_content.dig('message', 'text').present?,
        has_attachment: message_content.dig(:message, :attachment).present? || message_content.dig('message', 'attachment').present?
      }
    )

    Rails.logger.info(
      {
        service: 'Instagram::SendOnInstagramService',
        action: 'send_message',
        stage: 'before_post',
        instagram_id: instagram_id
      }
    )

    response = HTTParty.post(
      "https://graph.instagram.com/v22.0/#{instagram_id}/messages",
      body: message_content,
      query: query
    )

    Rails.logger.info(
      {
        service: 'Instagram::SendOnInstagramService',
        action: 'send_message',
        stage: 'after_post',
        instagram_id: instagram_id
      }
    )

    Rails.logger.info(
      {
        service: 'Instagram::SendOnInstagramService',
        action: 'send_message',
        instagram_id: instagram_id,
        status: response.code,
        body: response.parsed_response
      }
    )

    process_response(response, message_content)
  end

  def merge_human_agent_tag(params)
    params
  end
end
