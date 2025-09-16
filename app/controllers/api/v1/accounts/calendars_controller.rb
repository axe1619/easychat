class Api::V1::Accounts::CalendarsController < Api::V1::Accounts::BaseController

  skip_before_action :validate_bot_access_token!, only: %i[index show update], raise: false
  skip_before_action :ensure_current_user_is_not_a_bot!, only: %i[index show update], raise: false
  skip_before_action :current_account,            only: %i[index show update], raise: false

  skip_after_action  :verify_authorized,    only: %i[index show update], raise: false
  skip_after_action  :verify_policy_scoped, only: %i[index update],      raise: false
  
  before_action :check_authorization
  before_action :set_calendar, only: [:show, :destroy]

  # GET /calendars
  # Opcional: filtra por agent_bot_id => ?agent_bot_id=123
  #           (puedes agregar más filtros como platform, email, etc.)
  def index
    account_id = params[:account_id].to_i
    return render json: { error: 'account_id inválido' }, status: :bad_request if account_id <= 0
    scope = Calendar.where(account_id: account_id)
    scope = scope.where(agent_bot_id: params[:agent_bot_id]) if params[:agent_bot_id].present?
    @calendars = scope.order(id: :desc)
  end

  # GET /api/v1/accounts/:account_id/calendars/:id
  def show
    account_id = params[:account_id].to_i
    return render json: { error: 'account_id inválido' }, status: :bad_request if account_id <= 0
    @calendar = Calendar.find_by!(id: params[:id], account_id: account_id)
  end

  # POST /calendars
  def create
    # asegura que el bot pertenezca a la cuenta actual (si lo envían)
    if calendar_params[:agent_bot_id].present?
      bot = AgentBot.find_by(id: calendar_params[:agent_bot_id], account_id: Current.account.id)
      return render(json: { error: 'AgentBot inválido' }, status: :unprocessable_entity) unless bot
    end

    @calendar = Calendar.new(calendar_params)
    @calendar.account_id = Current.account.id

    if @calendar.save
      render :show, status: :created
    else
      render json: { errors: @calendar.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /calendars/:id
  def update
    account_id = params[:account_id].to_i
    return render json: { error: 'account_id inválido' }, status: :bad_request if account_id <= 0

    calendar = Calendar.find_by!(id: params[:id], account_id: account_id)
    attrs = calendar_params.except(:account_id) # nunca permitir mover de cuenta

    # (Opcional) coherencia del bot
    if attrs[:agent_bot_id].present? &&
      !AgentBot.exists?(id: attrs[:agent_bot_id], account_id: account_id)
      return render json: { error: 'AgentBot inválido para esta cuenta' }, status: :unprocessable_entity
    end

    if calendar.update(attrs)
      @calendar = calendar # para que el render :show funcione
      render :show
    else
      render json: { errors: calendar.errors.full_messages }, status: :unprocessable_entity
    end
  end


  # DELETE /calendars/:id
  def destroy
    @calendar.destroy
    head :no_content
  end

  private

  def set_calendar
    @calendar = policy_scope(Calendar).where(account_id: Current.account.id).find(params[:id])
  end

  def calendar_params
    # Ajusta los campos permitidos según tu migración/esquema
    params.require(:calendar).permit(
      :platform,
      :id_token,
      :access_token,
      :refresh_token,
      :agent_bot_id,
      :email,
      :user_name,
      :picture
    )
  end
end
