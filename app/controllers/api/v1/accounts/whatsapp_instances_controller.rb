class Api::V1::Accounts::WhatsappInstancesController < ApplicationController

  # POST /api/v1/accounts/:account_id/whatsapp_instances
  def create
    wi = whatsapp_instance_params
    result = ::Whatsapp::WhatsappInstanceService.create_instance(wi)
    render json: result, status: :created
  rescue ::Whatsapp::WhatsappInstanceService::Error => e
    render json: { error: e.message, status: e.status, body: e.body }, status: :bad_gateway
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/whatsapp_instances/:name/connect
  def connect
    name   = params.require(:instance_name)
    result = ::Whatsapp::WhatsappInstanceService.connect(name)
    render json: result
  rescue ::Whatsapp::WhatsappInstanceService::Error => e
    render json: { error: e.message, status: e.status, body: e.body }, status: :bad_gateway
  end

  # GET /api/v1/accounts/:account_id/whatsapp_instances/:name/state
  def state
    name   = params.require(:instance_name)
    result = ::Whatsapp::WhatsappInstanceService.connection_state(name)
    render json: result
  rescue ::Whatsapp::WhatsappInstanceService::Error => e
    render json: { error: e.message, status: e.status, body: e.body }, status: :bad_gateway
  end

  # POST /api/v1/accounts/:account_id/whatsapp_instances/:instance_name/set_webhook
  def set_webhook
    name = params[:instance_name] || params[:name] || params.require(:instance_name)

    body = params.permit(
      :enabled,
      :accountId,
      :token,
      :signMsg,
      :sign_delimiter,
      :reopenConversation,
      :conversationPending,
      :import_contacts,
      :import_messages,
      :days_limit_import_messages,
      :auto_create,
    ).to_h

    result = ::Whatsapp::WhatsappInstanceService.set_webhook(name, body)
    render json: result
  rescue ::Whatsapp::WhatsappInstanceService::Error => e
    render json: { error: e.message, status: e.status, body: e.body }, status: :bad_gateway
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def whatsapp_instance_params
  # require + permit evita el “permitted: false”
    params.require(:whatsapp_instance).permit(
      :instance_name,
      :chatwoot_account_id,
      :chatwoot_token,
      :chatwoot_url,
      :chatwoot_sign_msg,
      :chatwoot_reopen_conversation,
      :chatwoot_conversation_pending
    ).to_h
  end
end
