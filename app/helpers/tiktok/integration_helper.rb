module Tiktok::IntegrationHelper
  # Generates a signed JWT token for Tiktok integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @param code_verifier [String, nil] Optional PKCE code verifier to embed in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_tiktok_token(account_id, code_verifier: nil)
    return if client_secret.blank?

    JWT.encode(token_payload(account_id, code_verifier: code_verifier), client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate TikTok token: #{e.message}")
    nil
  end

  # Verifies and decodes a Tiktok JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Hash, nil] The decoded token payload or nil if invalid
  def verify_tiktok_token(token)
    return if token.blank? || client_secret.blank?

    decode_token(token, client_secret)
  end

  private

  def client_secret
    @client_secret ||= GlobalConfigService.load('TIKTOK_APP_SECRET', nil)
  end

  def token_payload(account_id, code_verifier: nil)
    payload = { sub: account_id, iat: Time.current.to_i }
    payload[:code_verifier] = code_verifier if code_verifier.present?
    payload
  end

  def decode_token(token, secret)
    decoded = JWT.decode(token, secret, true, {
                           algorithm: 'HS256',
                           verify_expiration: true
                         }).first
    decoded.with_indifferent_access
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Tiktok token: #{e.message}")
    nil
  end
end
