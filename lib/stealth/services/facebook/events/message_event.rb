# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Facebook

      class MessageEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_message
          fetch_location
          fetch_attachments
          fetch_nlp
        end

        private

          def fetch_message
            if params.dig('message', 'quick_reply').present?
              service_message.message = params.dig('message', 'text')
              service_message.payload = params.dig('message', 'quick_reply', 'payload')
            elsif params.dig('message', 'text').present?
              service_message.message = params.dig('message', 'text')
            end
          end

          def fetch_location
            if params.dig('message', 'attachments').present? && params.dig('message', 'attachments').is_a?(Array)
              params.dig('message', 'attachments').each do |attachment|
                next unless attachment['type'] == 'location'

                lat = attachment.dig('payload', 'coordinates', 'lat')
                lng = attachment.dig('payload', 'coordinates', 'long')

                service_message.location = {
                  lat: lat,
                  lng: lng
                }
              end
            end
          end

          def fetch_attachments
            if params.dig('message', 'attachments').present? && params.dig('message', 'attachments').is_a?(Array)
              params.dig('message', 'attachments').each do |attachment|
                # Seems to be a bug in Messenger, but in attachments of type `fallback`
                # we are seeing the URL come in at the attachment-level rather than
                # nested within the payload as the API specifies:
                # https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messages
                payload_url = if attachment.dig('payload', 'url').present?
                  attachment['payload']['url']
                else
                  attachment['url']
                end

                service_message.attachments << {
                  type: attachment['type'],
                  url: payload_url
                }
              end
            end
          end

          def fetch_nlp
            if params.dig('message', 'nlp').present?
              service_message.nlp_result = params.dig('message', 'nlp').as_json
            end
          end

      end

    end
  end
end
