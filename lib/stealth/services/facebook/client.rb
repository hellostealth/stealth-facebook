# coding: utf-8
# frozen_string_literal: true

require 'http'

require 'stealth/services/facebook/message_handler'
require 'stealth/services/facebook/reply_handler'
require 'stealth/services/facebook/setup'

module Stealth
  module Services
    module Facebook

      class Client < Stealth::Services::BaseClient
        FB_ENDPOINT = if ENV['FACEBOOK_API_VERSION'].present?
          "https://graph.facebook.com/v#{ENV['FACEBOOK_API_VERSION']}/me"
        else
          "https://graph.facebook.com/v3.2/me"
        end

        attr_reader :api_endpoint, :reply

        def initialize(reply:, endpoint: 'messages')
          @reply = reply
          access_token = "access_token=#{Stealth.config.facebook.page_access_token}"
          @api_endpoint = [[FB_ENDPOINT, endpoint].join('/'), access_token].join('?')
        end

        def transmit
          res = self
                  .class
                  .http_client
                  .post(api_endpoint, body: MultiJson.dump(reply))

          Stealth::Logger.l(
            topic: "facebook",
            message: "Transmitted. Response: #{res.status.code}: #{res.body}"
          )
        end

        def self.http_client
          headers = {
            'Content-Type' => 'application/json'
          }
          HTTP.timeout(connect: 15, read: 30).headers(headers)
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

          res = http_client.get(uri.to_s)
          Stealth::Logger.l(topic:
            'facebook',
            message: "Requested user profile for #{recipient_id}. Response: #{res.status.code}: #{res.body}"
          )

          if res.status.success?
            MultiJson.load(res.body.to_s)
          else
            raise(
              Stealth::Errors::ServiceError,
              "Facebook error #{res.status}: #{res.body}"
            )
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

          res = http_client.post(uri.to_s, body: MultiJson.dump(params))
          Stealth::Logger.l(
            topic: "facebook",
            message: "Sent custom event for metric: #{metric} and value: #{value}. Response: #{res.status}: #{res.body}"
          )

          if res.status.success?
            MultiJson.load(res.body.to_s)
          else
            raise(
              Stealth::Errors::ServiceError,
              "Facebook error #{res.status}: #{res.body}"
            )
          end
        end
      end

    end
  end
end
