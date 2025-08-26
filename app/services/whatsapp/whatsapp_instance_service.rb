require 'net/http'
require 'uri'
require 'json'

class Whatsapp::WhatsappInstanceService
  BASE_URL = ENV['WHATSAPP_BASE_URL'].presence || 'http://34.41.191.74:3030'
  API_KEY = ENV['WHATSAPP_API_KEY'].presence  || '429683C4C977415CAAFCCE10F7D57E11'

  class Error < StandardError
    attr_reader :status, :body
    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  def self.create_instance(wi)
      Rails.logger.info "create_instance wi: #{wi.inspect}"

      # Mapea tus keys snake_case → lo que espera el proveedor (ej. camelCase)
      payload = {
        integration: 'WHATSAPP-BAILEYS',
        qrcode: true,
        instanceName: wi['instance_name'],
        chatwoot: {
          accountId: wi['chatwoot_account_id'],
          token:     wi['chatwoot_token'],
          url:       wi['chatwoot_url'],
          signMsg:   wi['chatwoot_sign_msg'],
          reopenConversation:    wi['chatwoot_reopen_conversation'],
          conversationPending:   wi['chatwoot_conversation_pending']
        }
      }.compact

      post_request('/instance/create', payload)
    end

  def self.connect(name)
    get_request("/instance/connect/#{name}")
  end

  def self.connection_state(name)
    get_request("/instance/connectionState/#{name}")
  end

  def self.set_webhook(name, params)
    p = params.to_h

    payload = {
      'enabled'                  => p['enabled'].nil? ? p[:enabled] : p['enabled'],
      'accountId'                => p['accountId'] || p[:accountId],
      'token'                    => p['token']     || p[:token],
      'url'                      => "https://easycontact.top",
      'signMsg'                  => p['signMsg'].nil? ? p[:signMsg] : p['signMsg'],
      'sign_delimiter'           => p['sign_delimiter'] || p[:sign_delimiter] || "\n",
      'reopenConversation'       => p['reopenConversation'].nil? ? p[:reopenConversation] : p['reopenConversation'],
      'conversationPending'      => p['conversationPending'].nil? ? p[:conversationPending] : p['conversationPending'],
      'import_contacts'          => p['import_contacts'].nil? ? p[:import_contacts] : p['import_contacts'],
      'import_messages'          => p['import_messages'].nil? ? p[:import_messages] : p['import_messages'],
      'days_limit_import_messages'=> p['days_limit_import_messages'] || p[:days_limit_import_messages] || 0,
      'auto_create'              => p['auto_create'].nil? ? p[:auto_create] : p['auto_create'],
      'webhook_url'              => "#{BASE_URL}/chatwoot/webhook/#{name}"
    }.compact

    # Validación local mínima para evitar otro 400
    required = %w[enabled accountId token url signMsg reopenConversation conversationPending]
    missing  = required.reject { |k| payload.key?(k) }
    unless missing.empty?
      raise Error.new(
        "Faltan campos requeridos: #{missing.join(', ')}",
        status: 400,
        body: { missing: missing }.to_json
      )
    end

    post_request("/chatwoot/set/#{ERB::Util.url_encode(name)}", payload)
  end

  def self.get_request(path)
    uri     = URI.join(BASE_URL, path)
    request = Net::HTTP::Get.new(uri)
    request['apikey'] = API_KEY

    send_request(uri, request)
  end

  def self.post_request(path, payload)
    uri     = URI.join(BASE_URL, path)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['apikey']        = API_KEY
    request.body             = payload.to_json

    send_request(uri, request)
  end

  def self.send_request(uri, request)
    use_ssl = uri.scheme == 'https'
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error.new(
        "HTTP #{response.code} #{response.message}",
        status: response.code.to_i,
        body:   response.body
      )
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise Error.new("Respuesta no es JSON válido: #{e.message}", status: response.code.to_i, body: response.body)
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
    raise Error.new("No se pudo conectar con #{uri}", body: e.message)
  end

end
