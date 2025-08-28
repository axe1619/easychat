class Api::V1::Accounts::RagsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :set_rag, only: [:show, :update, :destroy]

  # GET /rags
  # Opcional: filtra por agent_bot_id: ?agent_bot_id=123
  def index
    # seguridad: SIEMPRE acota por la cuenta actual
    scope = policy_scope(Rag).where(account_id: Current.account.id)

    # si viene agent_bot_id en query, filtra también por bot
    if params[:agent_bot_id].present?
      scope = scope.where(agent_bot_id: params[:agent_bot_id])
    end

    # (opcional) valida si mandan account_id en query y no coincide
    if params[:account_id].present? && params[:account_id].to_i != Current.account.id
      return render json: { error: 'account_id inválido' }, status: :forbidden
    end

    @rags = scope.order(id: :desc)
  end

  # GET /rags/:id
  def show; end

  # POST /rags
  def create
    bot = AgentBot.find_by(id: rag_params[:agent_bot_id], account_id: Current.account.id)
    return render(json: { error: 'AgentBot inválido' }, status: :unprocessable_entity) unless bot

    @rag = Rag.new(rag_params)
    @rag.account_id = Current.account.id

    if @rag.save
      render :show, status: :created
    else
      render json: { errors: @rag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /rags/:id
  def update
    if @rag.update(rag_params.except(:account_id))
      render :show
    else
      render json: { errors: @rag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /rags/:id
  def destroy
    @rag.destroy
    head :no_content
  end

  private

  def set_rag
    @rag = policy_scope(Rag).where(account_id: Current.account.id).find(params[:id])
  end

  def rag_params
    params.require(:rag).permit(:agent_bot_id, :date, :collection_name, :description)
  end
end
