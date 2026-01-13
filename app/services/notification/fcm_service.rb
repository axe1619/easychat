class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze

  def initialize(project_id, credentials)
    @project_id = project_id
    @credentials = credentials
    @token_info = nil
  end

  def fcm_client
    FCM.new(current_token, credentials_path, @project_id)
  end

  private

  def current_token
    @token_info = generate_token if @token_info.nil? || token_expired?
    @token_info[:token]
  end

  def token_expired?
    Time.zone.now >= @token_info[:expires_at]
  end

  def generate_token
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: credentials_path,
      scope: SCOPES
    )
    token = authorizer.fetch_access_token!
    {
      token: token['access_token'],
      expires_at: Time.zone.now + token['expires_in'].to_i
    }
  end

  def credentials_path
    StringIO.new(normalized_credentials)
  end

  # Support credentials with escaped newlines or base64-encoded content (common when storing JSON in env vars)
  def normalized_credentials
    return @credentials unless @credentials.is_a?(String)

    credentials = @credentials.dup
    decoded_from_base64 = false

    # If the content looks like base64, try to decode it
    if credentials.match?(/\A[A-Za-z0-9+\/=\s]+\z/) && (credentials.length % 4).zero?
      decoded = Base64.decode64(credentials)
      unless decoded.empty?
        credentials = decoded
        decoded_from_base64 = true
      end
    end

    # If we already decoded a service account JSON, leave it as-is (it already contains \n escapes)
    return credentials if decoded_from_base64

    # Handle private keys stored with backslash-newline line continuations
    credentials = credentials.gsub("\\\n", "\\n")
    # Convert escaped newlines to real newlines for OpenSSL
    credentials = credentials.gsub('\\n', "\n")
    credentials
  end
end
