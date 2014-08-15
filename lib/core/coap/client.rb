module CoRE
  module CoAP
    # CoAP client library
    class Client
      attr_accessor :max_payload, :max_retransmit, :ack_timeout, :host, :port,
        :socket

      # @param  options   Valid options are (all optional): max_payload (maximum payload size, default 256), max_retransmit (maximum retransmission count, default 4), ack_timeout (timeout for ACK responses, default: 2), host (destination host), post (destination port, default 5683).
      def initialize(options = {})
        @max_payload    = options[:max_payload]     || 256
        @max_retransmit = options[:max_retransmit]  || 4
        @ack_timeout    = options[:ack_timeout]     || 2

        @host = options[:host]
        @port = options[:port] || 5683

        @retry_count = 0

        @socket = MySocket.new
        @socket.socket_type = UDPSocket
        @socket.ack_timeout = @ack_timeout

        @logger = CoAP.logger
      end

      # Enable DTLS Socket
      # Needs CoDTLS Gem
      def use_dtls
        @socket = MySocket.new
        @socket.socket_type = CoDTLS::SecureSocket
        @socket.ack_timeout = @ack_timeout

        self
      end

      def chunkify(string)
        chunks = []
        size = 2**((Math.log2(@max_payload).floor - 4) + 4)
        string.bytes.each_slice(size) { |s| chunks << s.pack('C*') }
        chunks
      end

      # GET
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def get(host, port, path, payload = nil, options = {})
        @retry_count = 0
        client(host, port, path, :get, payload, options)
      end

      # GET by aRI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def get_by_uri(uri, payload = nil, options = {})
        get(*decode_uri(uri), payload, options)
      end

      # POST
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def post(host, port, path, payload = nil, options = {})
        @retry_count = 0
        client(host, port, path, :post, payload, options)
      end

      # POST by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def post_by_uri(uri, payload = nil, options = {})
        post(*decode_uri(uri), payload, options)
      end

      # PUT
      #
      # @param  hsot      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def put(host, port, path, payload = nil, options = {})
        @retry_count = 0
        client(host, port, path, :put, payload, options)
      end

      # PUT by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def put_by_uri(uri, payload = nil, options = {})
        put(*decode_uri(uri), payload, options)
      end

      # DELETE
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def delete(host, port, path, payload = nil, options = {})
        @retry_count = 0
        client(host, port, path, :delete, payload, options)
      end

      # DELETE by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def delete_by_uri(uri, payload = nil, options = {})
        delete(*decode_uri(uri), payload, options)
      end

      # OBSERVE
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  callback  Method to call with the observe data. Must provide arguments payload and socket.
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def observe(host, port, path, callback, payload = nil, options = {})
        options[:observe] = 0
        client(host, port, path, :get, payload, options, callback)
      end

      # OBSERVE by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      # @param  payload   Payload
      # @param  callback  Method to call with the observe data. Must provide arguments payload and socket.
      #
      # @return CoAP::Message
      def observe_by_uri(uri, callback, payload = nil, options = {})
        observe(*decode_uri(uri), callback, payload, options)
      end

      private

      def client(host, port, path, method, payload, options, observe_callback = nil)
        # Set host and port only one time on multiple requests
        host.nil? ? (host = @host unless @host.nil?) : @host = host
        port.nil? ? (port = @port unless @port.nil?) : @port = port

        validate_arguments!(host, port, path, payload)

        szx = Math.log2(@max_payload).floor - 4

        # initialize block 2 with payload size
        block2 = Block.initialize(0, false, szx) 

        # Initialize block1 if set.
        block1 = if options[:block1].nil?
          Block.initialize(0, false, szx)
        else
          Block.decode(options[:block1])
        end

        # Initialize chunks if payload size > max_payload.
        chunks = chunkify(payload) unless payload.nil?

        # Create CoAP message struct.
        message = initialize_message(method, host, port, path, payload, block2)

        # If more than 1 chunk, we need to use block1.
        if !payload.nil? && chunks.size > 1
          # Increase block number.
          block1[:num] += 1 unless options[:block1].nil?

          # More chunks?
          if chunks.size > block1[:num] + 1
            block1[:more] = true
            message.options.delete(:block2)
          else
            block1[:more] = false
          end

          # Set final payload.
          message.payload = chunks[block1[:num]]

          # Set block1 message option.
          message.options[:block1] = Block.encode_hash(block1)
        end

        # Preserve user options.
        message.options[:block2] = options[:block2] unless options[:block2] == nil
        message.options[:observe] = options[:observe] unless options[:observe] == nil
        message.options.merge(options)

        log_message(:sending_message, message)

        # Connect via UDP/DTLS.
        @socket.connect host, port

        # Wait for answer and retry sending message if timeout rached.
        begin
          @socket.send message.to_wire
          recv_data = @socket.receive
        rescue Timeout::Error
          @retry_count += 1

          if @retry_count > @max_retransmit
            raise "Maximum retransmission count reached (#{@max_retransmit})."
          end

          retry
        end

        # Parse received data.
        recv_parsed = CoAP.parse(recv_data[0].force_encoding('BINARY'))

        log_message(:received_message, recv_parsed)

        # Payload is not fully transmitted.
        # TODO Get rid of nasty recursion.
        if block1[:more]
          fail 'Max Recursion' if @retry_count > 10
          return client(host, port, path, method, payload, message.options)
        end

        # Separated?
        if recv_parsed.tt == :ack && recv_parsed.payload.empty? && recv_parsed.mid == message.mid && recv_parsed.mcode[0] == 0 && recv_parsed.mcode[1] == 0
          @logger.debug '### SEPARATE REQUEST ###'

          # Wait for answer...
          recv_data = @socket.receive(600, @retry_count)
          recv_parsed = CoAP.parse(recv_data[0].force_encoding('BINARY'))

          log_message(:seperated_data, recv_parsed)

          if recv_parsed.tt == :con
            message = Message.new(:ack, 0, recv_parsed.mid, nil, {})
            message.options = { token: recv_parsed.options[:token] }
            @socket.send message.to_wire, 0
          end

          @logger.debug '### SEPARATE REQUEST END ###'
        end

        # Test for more block2 payload.
        block2 = Block.decode(recv_parsed.options[:block2])

        if block2[:more]
          block2[:num] += 1

          options.delete(:block1) # end block1
          options[:block2] = Block.encode_hash(block2)

          fail 'Max Recursion' if @retry_count > 50

          local_recv_parsed = client(host, port, path, method, nil, options)

          unless local_recv_parsed.nil?
            recv_parsed.payload << local_recv_parsed.payload
          end
        end

        # Token of received message mismatches.
        if recv_parsed.options[:token] != message.options[:token]
          fail ArgumentError, 'Received message with wrong token.'
        end

        # Do we need to observe?
        if recv_parsed.options[:observe]
          @Observer = CoAP::Observer.new
          @Observer.observe(recv_parsed, recv_data, observe_callback, @socket)
        end

        recv_parsed
      end

      # Decode CoAP URIs.
      def decode_uri(uri)
        uri = CoAP.scheme_and_authority_decode(uri.to_s)

        @logger.debug 'URI decoded: ' + uri.inspect
        fail ArgumentError, 'Invalid URI' if uri.nil?

        uri
      end

      def initialize_message(method, host, port, path, payload = nil, block2 = nil)
        mid   = SecureRandom.random_number(999)
        token = SecureRandom.random_number(256)

        options = {
          uri_path: CoAP.path_decode(path),
          token: token
        }

        message = Message.new(:con, method, mid, payload, options)

        # Temporary fix to disable early negotiation.
        if !block2.nil? && @may_payload != 256
          message.options[:block2] = Block.encode_hash(block2)
        end

        message
      end

      # Log message to debug log.
      def log_message(text, message)
        @logger.debug '###' + text.to_s.upcase.gsub('_', ' ')
        @logger.debug message.inspect
        @logger.debug message.to_s.hexdump if $DEBUG
      end

      # Raise ArgumentError exceptions on wrong client method arguments.
      def validate_arguments!(host, port, path, payload)
        if host.nil? || host.empty?
          fail ArgumentError, 'Argument «host» missing.'
        end

        if port.nil? || !port.is_a?(Integer)
          fail ArgumentError, 'Argument «port» missing or not an Integer.'
        end

        if path.nil? || path.empty?
          fail ArgumentError, 'Argument «path» missing.'
        end

        if !payload.nil? && (payload.empty? || !payload.is_a?(String))
          fail ArgumentError, 'Argument «payload» must be a non-emtpy String'
        end
      end
    end
  end
end
