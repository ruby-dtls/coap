module CoRE
  module CoAP
    class Observer
      MAX_OBSERVE_OPTION_VALUE = 8_388_608

      def initialize
        @logger = CoAP.logger

        @retry_count = 0
      end

      def observe(recv_parsed, recv_data, observe_callback, socket)
        observe_number = recv_parsed.options[:observe]
        observe_callback.call(recv_parsed, recv_data)

        loop do
          begin # TODO fix this
            recv_data = socket.receive(60, @retry_count)
          rescue Timeout::Error
            @retry_count = 0
            @logger.error 'Observe Timeout'
          end

          recv_parsed = CoAP.parse(recv_data[0].force_encoding('BINARY'))

          if recv_parsed.tt == :con
            message = Message.new(:ack, 0, recv_parsed.mid, nil, {})
            socket.send message.to_wire, 0
          end

          next unless recv_parsed.options[:observe]

          if observe_update?(observe_number, recv_parsed.options[:observe])
            observe_callback.call(recv_parsed, recv_data)
          end
        end
      end

      private

      def observe_update?(old, new)
        if new > old
          new - old < MAX_OBSERVE_OPTION_VALUE
        elsif new < old
          old - new > MAX_OBSERVE_OPTION_VALUE
        else
          false
        end
      end
    end
  end
end
