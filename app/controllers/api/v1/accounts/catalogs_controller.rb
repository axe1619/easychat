# app/controllers/api/v1/accounts/catalogs_controller.rb
class Api::V1::Accounts::CatalogsController < Api::V1::Accounts::BaseController 

  skip_before_action :validate_bot_access_token!, only: %i[index show], raise: false
  skip_before_action :ensure_current_user_is_not_a_bot!, only: %i[index show], raise: false
  skip_before_action :current_account,            only: %i[index show], raise: false

  skip_after_action  :verify_authorized,    only: %i[index show], raise: false
  skip_after_action  :verify_policy_scoped, only: %i[index],      raise: false

  before_action :check_authorization, except: %i[index show]
  before_action :set_catalog, only: %i[update destroy]

  def index
    account_id = params[:account_id].to_i
    return render json: { error: 'account_id inválido' }, status: :bad_request if account_id <= 0

    scope = Catalog.where(account_id: account_id)
    scope = scope.where(agent_bot_id: params[:agent_bot_id]) if params[:agent_bot_id].present?
    @catalogs = scope.order(id: :asc)
  end

  # GET /api/v1/accounts/:account_id/catalogs/:id
  def show
    account_id = params[:account_id].to_i
    @catalog = Catalog.find_by!(id: params[:id], account_id: account_id)
  end

  # GET /catalogs/:id
  # def show; end

  # POST /catalogs
  # { catalog: { codigo:, nombre:, descripcion:, agent_bot_id:, ... } }
  def create
    attrs = catalog_params.merge(account_id: Current.account.id)

    # opcional: verificar que el bot pertenece a la cuenta
    unless AgentBot.exists?(id: attrs[:agent_bot_id], account_id: Current.account.id)
      return render json: { error: 'AgentBot inválido para esta cuenta' }, status: :unprocessable_entity
    end

    @catalog = Catalog.new(attrs)
    authorize @catalog

    if @catalog.save
      render :show, status: :created
    else
      render json: { errors: @catalog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /catalogs/bulk_create
  # { catalogs: [ {...}, {...} ] }  o  [ {...}, {...} ] (top-level array)
  def bulk_create
    items = params[:catalogs] || params[:_json]
    return render json: { error: 'Se requiere un array de objetos' }, status: :unprocessable_entity unless items.is_a?(Array) && items.any?

    results = { created_ids: [], errors: [] }

    items.each_with_index do |raw_item, idx|
      item = permit_item(raw_item).merge(account_id: Current.account.id)

      unless item[:agent_bot_id].present? && AgentBot.exists?(id: item[:agent_bot_id], account_id: Current.account.id)
        results[:errors] << { index: idx, error: 'AgentBot inválido para esta cuenta', attrs: item.slice(:codigo, :nombre, :descripcion, :agent_bot_id) }
        next
      end

      catalog = Catalog.new(item)
      begin
        authorize catalog
      rescue Pundit::NotDefinedError
        # si no tienes policy, ignora; pero es recomendable definirla
      end

      if catalog.save
        results[:created_ids] << catalog.id
      else
        results[:errors] << { index: idx, messages: catalog.errors.full_messages, attrs: item.slice(:codigo, :nombre, :descripcion, :agent_bot_id) }
      end
    end

    status = results[:errors].any? ? :multi_status : :created
    render json: results.merge(created_count: results[:created_ids].size, failed_count: results[:errors].size), status:
  status
  end

  # PUT /catalogs/:id
  # Acepta payload parcial: { catalog: { descripcion: '...' } }
  def update
    authorize @catalog
    attrs = catalog_params.except(:account_id) # nunca permitir cambiar de cuenta

    if attrs[:agent_bot_id].present? &&
       !AgentBot.exists?(id: attrs[:agent_bot_id], account_id: Current.account.id)
      return render json: { error: 'AgentBot inválido para esta cuenta' }, status: :unprocessable_entity
    end

    if @catalog.update(attrs)
      render :show
    else
      render json: { errors: @catalog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /catalogs/:id
  def destroy
    authorize @catalog
    @catalog.destroy
    head :no_content
  end

  # POST /catalogs/bulk_destroy
  # Acepta:
  # { ids: [1,2,3] }  o  [1,2,3] (top-level array)
  def bulk_destroy
    ids = params[:ids] || params[:_json]
    ids = Array(ids).map(&:to_i).uniq
    return render json: { error: 'ids debe ser un array no vacío' }, status: :unprocessable_entity if ids.empty?

    scope = policy_scope(Catalog).where(account_id: Current.account.id, id: ids)
    count = scope.size
    scope.destroy_all

    render json: { deleted_count: count, ids: ids }, status: :ok
  end

  private

  def set_catalog
    @catalog = policy_scope(Catalog).where(account_id: Current.account.id).find(params[:id])
  end

  # strong params estándar (para create/update)
  def catalog_params
    params.require(:catalog).permit(*permitted_attrs)
  end

  # para cada ítem en bulk_create (sin require :catalog)
  def permit_item(item)
    ActionController::Parameters.new(item).permit(*permitted_attrs)
  end

  def permitted_attrs
    [
      :codigo, :nombre, :descripcion, :descripcion_larga, :categoria, :subcategoria, :precio, :moneda,
      :unidad_medida, :presentacion, :stock_disponible, :stock_minimo, :descuento, :precio_oferta,
      :impuesto, :estado, :marca, :proveedor, :codigo_barras, :imagen_url, :galeria_imagenes,
      :ficha_tecnica_url, :manual_url, :video_url, :pais_origen, :garantia, :fecha_creacion,
      :fecha_actualizacion, :etiquetas, :politicas_envio, :politicas_devolucion, :variantes,
      :relacionados, :ratings, :agent_bot_id, :account_id
    ]
  end
end
