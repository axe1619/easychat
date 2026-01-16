class SendReplyJob < ApplicationJob
  queue_as :high

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    channel_name = conversation.inbox.channel.class.to_s
    Rails.logger.info(
      {
        service: 'SendReplyJob',
        action: 'perform',
        message_id: message.id,
        conversation_id: conversation.id,
        channel_name: channel_name,
        conversation_type: conversation.additional_attributes['type']
      }
    )

    services = {
      'Channel::TwitterProfile' => ::Twitter::SendOnTwitterService,
      'Channel::TwilioSms' => ::Twilio::SendOnTwilioService,
      'Channel::Line' => ::Line::SendOnLineService,
      'Channel::Telegram' => ::Telegram::SendOnTelegramService,
      'Channel::Tiktok' => ::Tiktok::SendOnTiktokService,
      'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
      'Channel::Sms' => ::Sms::SendOnSmsService,
      'Channel::Instagram' => ::Instagram::SendOnInstagramService
    }

    case channel_name
    when 'Channel::FacebookPage'
      Rails.logger.info(
        {
          service: 'SendReplyJob',
          action: 'dispatch',
          channel_name: channel_name,
          dispatch_to: conversation.additional_attributes['type'] == 'instagram_direct_message' ? 'Instagram::Messenger::SendOnInstagramService' : 'Facebook::SendOnFacebookService'
        }
      )
      send_on_facebook_page(message)
    else
      Rails.logger.info(
        {
          service: 'SendReplyJob',
          action: 'dispatch',
          channel_name: channel_name,
          dispatch_to: services[channel_name]&.name
        }
      )
      services[channel_name].new(message: message).perform if services[channel_name].present?
    end
  end

  private

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::Messenger::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
