class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]
  COUNT_MESSAGE_CONVERSATION = ENV.fetch('ANALIZE_IA_COVERSATION', 10).to_i - 2

  def index
    @messages = conversation.nil? ? [] : message_finder.perform
  end

  def create
    assigned_state_conversation
    @message = conversation.messages.new(message_params)
    build_attachment
    @message.save!
  end

  def assigned_state_conversation
    if conversation.conversations_state_id.present?
      return 
    end
    override_messages = Message.where(account_id: conversation.account_id,inbox_id: conversation.inbox_id,conversation_id: conversation.id)
                                .offset(COUNT_MESSAGE_CONVERSATION).exists?
    if(!override_messages)
      return
    end
    # fetch ia    
    state_assigned_by_agent_ia = http_get_analize_conversation(conversation.account_id,conversation.display_id)
    if state_assigned_by_agent_ia.nil?
      return
    end
    conversation_state = ConversationState.find_by(id: state_assigned_by_agent_ia["id"])
    if conversation_state.nil?
      return
    end
    conversation.update(conversations_state_id: conversation_state.id)
  end

  def http_get_analize_conversation(account_id , display_id)
    url_get_analize = ENV.fetch('CLOUD_RUN_ANALIZE_CONVERSATION', '')
    params    = { account_id: account_id, display_id: display_id }
    uri       = URI(url_get_analize)
    uri.query = URI.encode_www_form(params)
    begin
      response  = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      response_data = JSON.parse(response.body)
      if !response_data['status'] 
        return nil
      end
      return JSON.parse(response_data["data"])
    rescue StandardError => e
      return nil
    end
  end

  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { email: contact_email, name: contact_name },
        retain_original_contact_name: true
      ).perform
    else
      @message.update!(message_update_params[:message])
    end
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: :internal_server_error
  end

  private

  def build_attachment
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = helpers.file_type(uploaded_attachment&.content_type) if uploaded_attachment.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end

  def set_conversation
    @conversation = create_conversation if conversation.nil?
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before],
      after: permitted_params[:after]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(conversation, message_finder_params)
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
  end

  def permitted_params
    # timestamp parameter is used in create conversation method
    params.permit(:id, :before, :after, :website_token, contact: [:name, :email], message: [:content, :referer_url, :timestamp, :echo_id, :reply_to])
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
end
