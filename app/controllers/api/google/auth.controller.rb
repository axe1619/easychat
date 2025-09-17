module Api
  module Google
    class AuthController < ActionController::API
      def oauth2callback
        render plain: 'hola mundo'
      end
    end
  end
end