class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  include Events::Types
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    # Authenticate user via the temporary sso auth token
    if params[:sso_auth_token].present? && @resource.present?
      authenticate_resource_with_sso_token
      validate_session_limit(@resource, Current.account)
      yield @resource if block_given?
      render_create_success
    else
      super do |user|
        validate_session_limit(user,Current.account)
      end
    end
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def validate_session_limit(user,account)
    return unless user&.persisted?
    return unless user.tokens.is_a?(Hash)
    tokens = user.tokens
    max_sessions = user.max_sessions.to_i
    return if max_sessions <= 0 || tokens.size <= max_sessions
    sessions = tokens.map { |id, data| { session_id: id, expiry: data['expiry'].to_i } }
    # newest → oldest
    sessions.sort_by! { |s| s[:expiry] }.reverse!
    sessions_to_remove = sessions.drop(max_sessions)
    sessions_to_remove.each do |session|
      tokens.delete(session[:session_id])
    end
    user.save!(validate: false)
    Rails.configuration.dispatcher.dispatch(
      SESSION_DELETED,
      Time.zone.now,
      user: user,
      sessions: sessions_to_remove
    )
  end

  def login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    "#{frontend_url}/app/login?error=#{error}"
  end

  def authenticate_resource_with_sso_token
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])
    @resource = user if user&.valid_sso_auth_token?(params[:sso_auth_token])
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
