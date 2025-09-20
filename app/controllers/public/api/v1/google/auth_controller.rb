require 'net/http'
require 'uri'
require 'json'

module Public
  module Api
    module V1
      module Google
        class AuthController < ActionController::API
          # GET /api/google
          # Redirige a Google OAuth2 consentimiento
          def google
            client_id      = ENV['GOOGLE_CLIENT_ID']
            redirect_uri   = ENV['GOOGLE_REDIRECT_URI'] # Debe coincidir con el callback configurado
            if client_id.blank? || redirect_uri.blank?
              return render json: { message: 'Se requiere GOOGLE_CLIENT_ID y GOOGLE_REDIRECT_URI' }, status: :not_found
            end

            auth_endpoint = 'https://accounts.google.com/o/oauth2/v2/auth'

            scopes = [
              'openid',
              'email',
              'profile',
              'https://www.googleapis.com/auth/calendar.events'
            ].join(' ')

            query = URI.encode_www_form(
              client_id: client_id,
              redirect_uri: redirect_uri,
              response_type: 'code',
              scope: scopes,
              access_type: 'offline',
              prompt: 'consent'
            )

            redirect_to "#{auth_endpoint}?#{query}", allow_other_host: true
          end

          # GET /api/oauth2callback?code=...
          # Intercambia el code por tokens y retorna un script que hace postMessage a tu frontend
          def oauth2callback
            code = params[:code].to_s
            return render plain: 'No se recibió ningún código de autorización', status: :bad_request if code.blank?

            client_id     = ENV['GOOGLE_CLIENT_ID']
            client_secret = ENV['GOOGLE_CLIENT_SECRET']
            redirect_uri  = ENV['GOOGLE_REDIRECT_URI']
            origin        = ENV['FRONTEND_URL']

            if [client_id, client_secret, redirect_uri, origin].any?(&:blank?)
              return render plain: 'Faltan variables de entorno (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REDIRECT_URI, API_EASY_CONTACT)', status: :internal_server_error
            end

            tokens = exchange_code_for_tokens(code, client_id, client_secret, redirect_uri)
            unless tokens && tokens['access_token']
              return render plain: 'Error al obtener tokens de Google', status: :internal_server_error
            end

            access_token  = tokens['access_token']
            refresh_token = tokens['refresh_token'] # puede venir nil si Google no lo envía
            id_token      = tokens['id_token']

            userinfo = fetch_userinfo(access_token)
            unless userinfo && userinfo['sub']
              return render plain: 'Error al obtener userinfo de Google', status: :internal_server_error
            end

            user_data = {
              sub:            userinfo['sub'],
              email:          userinfo['email'],
              name:           userinfo['name'],
              picture:        userinfo['picture'],
              email_verified: userinfo['email_verified']
            }

            script = <<~HTML
              <script>
                try {
                  window.opener && window.opener.postMessage({
                    access_token: #{access_token.to_json},
                    refresh_token: #{refresh_token.to_json},
                    id_token: #{id_token.to_json},
                    user: #{user_data.to_json}
                  }, #{origin.to_json});
                } catch (e) {
                  console.error('postMessage error', e);
                } finally {
                  window.close();
                }
              </script>
            HTML

            # Al ser API controller, usamos content_type text/html
            render plain: script, content_type: 'text/html; charset=utf-8'
          rescue => e
            Rails.logger.error("[oauth2callback] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
            render plain: 'Error al obtener tokens/datos de Google', status: :internal_server_error
          end

          private

          def exchange_code_for_tokens(code, client_id, client_secret, redirect_uri)
            uri = URI('https://oauth2.googleapis.com/token')
            req = Net::HTTP::Post.new(uri)
            req.set_form_data(
              code: code,
              client_id: client_id,
              client_secret: client_secret,
              redirect_uri: redirect_uri,
              grant_type: 'authorization_code'
            )

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            res = http.request(req)

            return JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
            Rails.logger.error("[exchange_code_for_tokens] HTTP #{res.code} - #{res.body}")
            nil
          end

          def fetch_userinfo(access_token)
            uri = URI('https://openidconnect.googleapis.com/v1/userinfo')
            req = Net::HTTP::Get.new(uri)
            req['Authorization'] = "Bearer #{access_token}"

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            res = http.request(req)

            return JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
            Rails.logger.error("[fetch_userinfo] HTTP #{res.code} - #{res.body}")
            nil
          end
        end
      end
    end
  end
end
