module CoRE
  module CoAP
    # Socket abstraction.
    class Ether
      DEFAULT_RECV_TIMEOUT = 2

      attr_accessor :max_retransmit, :recv_timeout
      attr_reader :address_family, :socket

      def initialize(options = {})
        @socket_class   = options[:socket_class]   || Celluloid::IO::UDPSocket
        @address_family = options[:address_family] || Socket::AF_INET6
        @recv_timeout   = options[:recv_timeout]   || DEFAULT_RECV_TIMEOUT
        @max_retransmit = options[:max_retransmit] || 4

        @socket = @socket_class.new(@address_family)
      end

      def receive(options = {})
        retry_count = options[:retry_count] || 0
        timeout = (options[:timeout] || @recv_timeout) ** (retry_count + 1)

        data = Timeout.timeout(timeout) do
          @socket.recvfrom(1024)
        end

        answer = CoAP.parse(data[0].force_encoding('BINARY'))

        if answer.tt == :con
          message = Message.new(:ack, 0, answer.mid, nil,
            {token: answer.options[:token]})

          send(message, data[1][3])
        end

        answer
      end

      def send(message, host, port = CoAP::PORT)
        message = message.to_wire if message.respond_to?(:to_wire)
        @socket.send(message, Socket::MSG_DONTWAIT, host, port)
      end

      def send_and_receive(message, host, port = CoAP::PORT)
        retry_count = 0

        begin
          send(message, host, port)
          receive(retry_count: retry_count)
        rescue Timeout::Error
          retry_count += 1

          if retry_count > @max_retransmit
            raise "Maximum retransmission count of #{@max_retransmit} reached."
          end

          retry
        end
      end

      class << self
        def from_host(host, options = {})
          if IPAddr.new(host).ipv6? 
            new
          else
            new(options.merge(address_family: Socket::AF_INET))
          end
        rescue IPAddr::InvalidAddressError
          host = Resolver.address(host)
          retry
        end

        def send(*args)
          invoke(:send, *args)
        end

        def send_and_receive(*args)
          invoke(:send_and_receive, *args)
        end

        private

        def invoke(method, *args)
          options = {}
          options = args.pop if args.last.is_a? Hash

          ether = from_host(args[1], options)

          [ether, ether.__send__(method, *args)]
        end
      end
    end
  end
end
