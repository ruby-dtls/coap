module CoRE
  module CoAP
    class Observer
      MAX_OBSERVE_OPTION_VALUE = 8_388_608

      def initialize
        @logger = CoAP.logger
      end

      def observe(message, callback, socket)
        n = message.options[:observe]

        callback.call(socket, message)

        # This does not seem to be able to cope with concurrency.
        loop do
          answer = socket.receive(timeout: 0)

          next unless answer.options[:observe]

          if update?(n, answer.options[:observe])
            callback.call(socket, answer)
          end
        end
      end

      private

      def update?(old, new)
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
