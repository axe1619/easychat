# frozen_string_literal: true

module Messages
  module MarkdownRenderers
    # Minimal base to support instagram markdown rendering without breaking boot
    class BaseRenderer
      def initialize(message:, attachment: nil)
        @message = message
        @attachment = attachment
      end

      private

      def render_template(template, locals = {})
        ApplicationController.render(
          template: "messages/markdown_renderers/#{template}",
          locals: locals
        )
      rescue StandardError => e
        Rails.logger.debug { "BaseRenderer render_template fallback: #{e.message}" }
        nil
      end

      def render_attachment(attachment)
        attachment
      end
    end
  end
end
