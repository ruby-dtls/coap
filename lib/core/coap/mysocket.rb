module CoRE
  module CoAP
    class MySocket
      attr_writer :socket_type, :ack_timeout

      def initialize
        @logger = CoAP.logger
      end

      def connect(host, port)
        address = IPAddr.new(host)
        connect_socket(address, port)
      rescue ArgumentError # host is not ip address
        addresses = IPv6FavorResolv.getaddresses(host)

        raise Resolv::ResolvError if addresses.empty?

        addresses.each do |address|
          begin
            # Transform to IPAddr object
            address = IPAddr.new(address.to_s)
            connect_socket(address, port)
          rescue Errno::EHOSTUNREACH
            @logger.fatal 'Address unreachable: ' + address.to_s if $DEBUG
          rescue Errno::ENETUNREACH
            @logger.fatal 'Net unreachable: ' + address.to_s if $DEBUG
          end
        end
      end

      def send(data, flags = 0)
        @socket.send(data, flags)
      end

      def receive(timeout = nil, retry_count = 0)
        timeout = @ack_timeout**(retry_count + 1) if timeout.nil?

        @logger.debug @socket.peeraddr.inspect
        @logger.debug @socket.addr.inspect
        @logger.debug 'Current timeout value: ' + timeout.to_s

        recv_data = nil
        status = Timeout.timeout(timeout) do
          recv_data = @socket.recvfrom(1024)
        end

        recv_data
      end

      private

      def connect_socket(address, port)
        if address.ipv6?
          @socket = @socket_type.new(Socket::AF_INET6)
        else
          @socket = @socket_type.new
        end

        # TODO: Error handling connection
        @socket.connect(address.to_s, port)

        @socket
      end
    end
  end
end
