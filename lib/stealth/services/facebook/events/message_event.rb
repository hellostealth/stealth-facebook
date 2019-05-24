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
                service_message.attachments << {
                  type: attachment['type'],
                  url: attachment['payload']['url']
                }
              end
            end
          end

      end

    end
  end
end
