# coding: utf-8
# frozen_string_literal: true

require 'faraday'

require 'stealth/services/facebook/message_handler'
require 'stealth/services/facebook/reply_handler'
require 'stealth/services/facebook/setup'

module Stealth
  module Services
    module Facebook

      class Client < Stealth::Services::BaseClient
        FB_ENDPOINT = "https://graph.facebook.com/v2.10/me"

        attr_reader :api_endpoint, :reply

        def initialize(reply:, endpoint: 'messages')
          @reply = reply
          access_token = "access_token=#{Stealth.config.facebook.page_access_token}"
          @api_endpoint = [[FB_ENDPOINT, endpoint].join('/'), access_token].join('?')
        end

        def transmit
          headers = { "Content-Type" => "application/json" }
          response = Faraday.post(api_endpoint, reply.to_json, headers)
          Stealth::Logger.l(topic: "facebook", message: "Transmitting. Response: #{response.status}: #{response.body}")
        end

        def self.fetch_profile(recipient_id:, fields: nil)
          if fields.blank?
            fields = [:id, :name, :first_name, :last_name, :profile_pic]
          end

          query_hash = {
            fields: fields.join(','),
            access_token: Stealth.config.facebook.page_access_token
          }

          uri = URI::HTTPS.build(
            host: "graph.facebook.com",
            path: "/#{recipient_id}",
            query: query_hash.to_query
          )

          response = Faraday.get(uri.to_s)
          Stealth::Logger.l(topic: "facebook", message: "Requested user profile for #{recipient_id}. Response: #{response.status}: #{response.body}")

          if response.status.in?(200..299)
            MultiJson.load(response.body)
          else
            raise(Stealth::Errors::ServiceError, "Facebook error #{response.status}: #{response.body}")
          end
        end

        def self.track(recipient_id:, metric:, value:, options: {})
          metric_values = [{
            '_eventName' => metric,
            '_valueToSum' => value
          }]

          metric_values.first.merge!(options)

          params = {
            event: 'CUSTOM_APP_EVENTS',
            custom_events: MultiJson.dump(metric_values),
            advertiser_tracking_enabled: 1,
            application_tracking_enabled: 1,
            extinfo: MultiJson.dump(['mb1']),
            page_scoped_user_id: recipient_id,
            page_id: Stealth.config.facebook.page_id
          }

          uri = URI::HTTPS.build(
            host: "graph.facebook.com",
            path: "/#{Stealth.config.facebook.app_id}/activities"
          )

          response = Faraday.post(uri.to_s, params)
          Stealth::Logger.l(topic: "facebook", message: "Sending custom event for metric: #{metric} and value: #{value}. Response: #{response.status}: #{response.body}")

          if response.status.in?(200..299)
            MultiJson.load(response.body)
          else
            raise(Stealth::Errors::ServiceError, "Facebook error #{response.status}: #{response.body}")
          end
        end
      end

    end
  end
end
