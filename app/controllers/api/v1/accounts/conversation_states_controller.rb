class Api::V1::Accounts::ConversationStatesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_conversation_state, except: [:index, :create]
  before_action :check_authorization
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @conversation_states = Current.account.conversation_states
  end

  def show; 
  end

  def create
    @conversation_state = Current.account.conversation_states.create!(permitted_params)
  end

  def update
    @conversation_state.update!(permitted_params)
  end

  def destroy
    @conversation_state.destroy!
    head :ok
  end

  private

  def fetch_conversation_state
    @conversation_state = Current.account.conversation_states.find(params[:id])
  end

  def permitted_params
    params.require(:conversation_state).permit(:name, :description, :color, notification: {})
  end
end
