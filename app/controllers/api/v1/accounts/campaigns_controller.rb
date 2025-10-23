class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    scope = Current.account.campaigns.order(created_at: :desc)
    scope = scope.where('created_at < ?', params[:created_at]) if params[:created_at].present?
    @campaigns = scope.limit(5)
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  def messages
    status = params[:status]
    status = [:delivered, :read] if status.blank? || status.to_s == "success"
    status = [:sent] if status.blank? || status.to_s == "pending"
    @messages = get_message_campaign(@campaign.id, status)
  end

  private

  def get_message_campaign(campaignId,status)
    Message.campaign(campaignId, status)
    .joins(conversation: :contact)
    .select([
      'messages.*',
      'conversations.display_id as conversation_display_id',
      'contacts.id AS contact_id',
      'contacts.name AS contact_name',
      'contacts.phone_number AS contact_phone_number'
    ].join(', '))
  end

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, additional_attributes: {} , audience: [:type, :id], trigger_rules: {})
  end
end
