# app/controllers/api/v1/accounts/rags_controller.rb
class Api::V1::Accounts::RagsController < Api::V1::Accounts::BaseController
  # --- Desbloquear index/show (como en CatalogsController) ---
  skip_before_action :validate_bot_access_token!,  only: %i[index show], raise: false
  skip_before_action :ensure_current_user_is_not_a_bot!, only: %i[index show], raise: false
  skip_before_action :current_account,             only: %i[index show], raise: false

  skip_after_action  :verify_authorized,    only: %i[index show], raise: false
  skip_after_action  :verify_policy_scoped, only: %i[index],      raise: false

  # --- Mantener protección en create/update/destroy ---
  before_action :check_authorization, except: %i[index show]
  before_action :set_rag, only: %i[update destroy]

  # GET /api/v1/accounts/:account_id/rags?agent_bot_id=123
  def index
    account_id = params[:account_id].to_i
    return render json: { error: 'account_id inválido' }, status: :bad_request if account_id <= 0

    scope = Rag.where(account_id: account_id)
    scope = scope.where(agent_bot_id: params[:agent_bot_id]) if params[:agent_bot_id].present?
    @rags = scope.order(id: :asc) # usa :desc si prefieres descendente
  end

  # GET /api/v1/accounts/:account_id/rags/:id
  def show
    account_id = params[:account_id].to_i
    @rag = Rag.find_by!(id: params[:id], account_id: account_id)
  end

  # POST /rags  (protegido)
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

  # PUT /rags/:id  (protegido)
  def update
    if @rag.update(rag_params.except(:account_id))
      render :show
    else
      render json: { errors: @rag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /rags/:id  (protegido)
  def destroy
    @rag.destroy
    head :no_content
  end

  private

  # Solo para acciones protegidas
  def set_rag
    @rag = policy_scope(Rag).where(account_id: Current.account.id).find(params[:id])
  end

  def rag_params
    params.require(:rag).permit(:agent_bot_id, :date, :collection_name, :description)
  end
end
