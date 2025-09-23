# app/controllers/public/api/v1/redirects/agent_rag_controller.rb
require 'net/http'
require 'uri'
require 'securerandom'
require 'openssl'

module Public
  module Api
    module V1
      module Redirects
        class AgentRagController < ApplicationController
          # POST /api/redirects/add_pdf
          def add_pdf
            collection_name = params[:collectionName]
            uploaded_file   = params[:file] # ActionDispatch::Http::UploadedFile

            # Base desde ENV (con default por si no está seteada)
            base    = ENV.fetch('AGENTIC_EASY_CONTACT')
            # Asegura una slash final para que URI.join no “pise” el host
            base    = base.end_with?('/') ? base : "#{base}/"
            uri     = URI.join(base, 'api/rag/add-pdf')

            boundary = "----RubyFormBoundary#{SecureRandom.hex(12)}"
            crlf = "\r\n"

            body_parts = []
            # campo collectionName
            body_parts << "--#{boundary}#{crlf}"
            body_parts << "Content-Disposition: form-data; name=\"collectionName\"#{crlf}#{crlf}"
            body_parts << collection_name.to_s + crlf

            # campo file
            body_parts << "--#{boundary}#{crlf}"
            body_parts << "Content-Disposition: form-data; name=\"file\"; filename=\"#{uploaded_file.original_filename}\"#{crlf}"
            body_parts << "Content-Type: #{uploaded_file.content_type}#{crlf}#{crlf}"
            body_parts << uploaded_file.read
            body_parts << crlf
            body_parts << "--#{boundary}--#{crlf}"

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE # solo para localhost

            req = Net::HTTP::Post.new(uri.request_uri)
            req['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
            req.body = body_parts.join

            http.request(req)

            render json: { message: 'ok' }, status: :ok
          end

          def delete_collection
            name = params[:name].to_s
            return render json: { error: 'missing name' }, status: :bad_request if name.blank?

            base = ENV['AGENTIC_EASY_CONTACT'].presence
            # Construye: <base>/api/rag/delete-collection/:name (escapado)
            uri = URI.join(base, "/api/rag/delete-collection/", CGI.escape(name))

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')

            req = Net::HTTP::Delete.new(uri.request_uri)
            res = http.request(req)

            if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPNoContent)
              render json: { message: 'ok', name: name }, status: :ok
            else
              render json: { error: 'external delete failed', status: res.code }, status: :bad_gateway
            end
          rescue => e
            render json: { error: e.message }, status: :bad_gateway
          end
        end
      end
    end
  end
end
