# coding: utf-8
# frozen_string_literal: true

module Stealth
  module Services
    module Facebook

      class MessageReadsEvent

        attr_reader :service_message, :params

        def initialize(service_message:, params:)
          @service_message = service_message
          @params = params
        end

        def process
          fetch_read
        end

        private

          def fetch_read
            service_message.payload = params['read']
          end
      end

    end
  end
end
