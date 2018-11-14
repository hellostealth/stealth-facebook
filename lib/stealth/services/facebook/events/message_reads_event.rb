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
            service_message.read = { watermark: get_timestamp, seq: params['read']['seq'] }
          end

          def get_timestamp
            Time.at(params['read']['watermark']/1000).to_datetime
          end
      end

      module ReadsEvent
        attr_accessor :read
        def initialize(service:)
          @read = {}
          super
        end
      end

    end
  end


  class ServiceMessage
    prepend Services::Facebook::ReadsEvent
  end
end
