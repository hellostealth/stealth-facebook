# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Facebook

      class MessagingReferralEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_referral
        end

        private

          def fetch_referral
            service_message.referral = params['referral']
          end

      end

    end
  end
end
