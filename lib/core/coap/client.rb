# encoding: utf-8

module CoRE
  module CoAP
    # CoAP client library
    class Client
      attr_accessor :max_payload, :host, :port

      # @param  options   Valid options are (all optional): max_payload
      #                   (maximum payload size, default 256), max_retransmit
      #                   (maximum retransmission count, default 4),
      #                   recv_timeout (timeout for ACK responses, default: 2),
      #                   host (destination host), post (destination port,
      #                   default 5683), dtls_id (DTLS client identity)
      #                   and dtls_key (DTLS pre-shared key).
      def initialize(options = {})
        @max_payload = options[:max_payload] || 256

        @host = options[:host]
        @port = options[:port] || CoAP::PORT

        @options = options

        @logger = CoAP.logger
      end

      # Enable DTLS socket.
      def use_dtls
        require 'tinydtls'

        id  = @options[:dtls_id]
        key = @options[:dtls_key]

        if id.nil? or key.nil?
          raise ArgumentError.new("DTLS support requires specification of an identity/key pair")
        end

        @options[:socket] = TinyDTLS::UDPSocket.new
        @options[:socket].add_client(id, key)

        self
      end

      # GET
      #
      # @param  path      Path
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def get(*args)
        client(:get, *args)
      end

      # GET by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def get_by_uri(uri, *args)
        get(*decode_uri(uri), *args)
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
      def post(*args)
        client(:post, *args)
      end

      # POST by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def post_by_uri(uri, *args)
        post(*decode_uri(uri), *args)
      end

      # PUT
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def put(*args)
        client(:put, *args)
      end

      # PUT by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def put_by_uri(uri, *args)
        put(*decode_uri(uri), *args)
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
      def delete(*args)
        client(:delete, *args)
      end

      # DELETE by URI
      #
      # @param  uri       URI
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def delete_by_uri(uri, *args)
        delete(*decode_uri(uri), *args)
      end

      # OBSERVE
      #
      # @param  host      Destination host
      # @param  port      Destination port
      # @param  path      Path
      # @param  callback  Method to call with the observe data. Must provide
      #                   arguments payload and socket.
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def observe(path, host, port, callback, payload = nil, options = {})
        options[:observe] = 0
        client(:get, path, host, port, payload, options, callback)
      end

      # OBSERVE by URI
      #
      # @param  uri       URI
      # @param  callback  Method to call with the observe data. Must provide
      #                   arguments payload and socket.
      # @param  payload   Payload
      # @param  options   Options
      #
      # @return CoAP::Message
      def observe_by_uri(uri, *args)
        observe(*decode_uri(uri), *args)
      end

      private

      def client(method, path, host = nil, port = nil, payload = nil, options = {}, observe_callback = nil)
        # Set host and port only one time on multiple requests
        host.nil? ? (host = @host unless @host.nil?) : @host = host
        port.nil? ? (port = @port unless @port.nil?) : @port = port

        path, query = path.split('?')

        validate_arguments!(host, port, path, payload)

        szx = 2 ** CoAP.number_of_bits_up_to(@max_payload)

        # Initialize block2 with payload size.
        block2 = Block.new(0, false, szx)

        # Initialize block1.
        block1 = if options[:block1].nil?
          Block.new(0, false, szx)
        else
          Block.new(options[:block1]).decode
        end

        # Initialize chunks if payload size > max_payload.
        if !payload.nil? && payload.bytesize > @max_payload
          chunks = Block.chunkify(payload, @max_payload)
        else
          chunks = [payload]
        end

        # Create CoAP message struct.
        message = initialize_message(method, path, query, payload)
        message.mid = options.delete(:mid) if options[:mid]

        # Set message type to non if chosen in global or local options.
        if options.delete(:tt) == :non || @options.delete(:tt) == :non
          message.tt = :non
        end

        # If more than 1 chunk, we need to use block1.
        if !payload.nil? && chunks.size > 1
          # Increase block number.
          block1.num += 1 unless options[:block1].nil?

          # More chunks?
          if chunks.size > block1.num + 1
            block1.more = true
            message.options.delete(:block2)
          else
            block1.more = false
          end

          # Set final payload.
          message.payload = chunks[block1.num]

          # Set block1 message option.
          message.options[:block1] = block1.encode
        end

        # Preserve user options.
        message.options[:block2] = options[:block2] unless options[:block2] == nil
        message.options[:observe] = options[:observe] unless options[:observe] == nil

        options.delete(:block1)
        message.options.merge!(options)

        log_message(:sending_message, message)

        # Wait for answer and retry sending message if timeout reached.
        @transmission, recv_parsed = Transmission.request(message, host, port, @options)

        log_message(:received_message, recv_parsed)

        # Payload is not fully transmitted.
        # TODO Get rid of nasty recursion.
        if block1.more
          return client(method, path, host, port, payload, message.options)
        end

        # Test for more block2 payload.
        block2 = Block.new(recv_parsed.options[:block2]).decode

        if block2.more
          block2.num += 1

          options.delete(:block1) # end block1
          options[:block2] = block2.encode

          local_recv_parsed = client(method, path, host, port, nil, options)

          unless local_recv_parsed.nil?
            recv_parsed.payload << local_recv_parsed.payload
          end
        end

        # Do we need to observe?
        if recv_parsed.options[:observe]
          CoAP::Observer.new.observe(recv_parsed, observe_callback, @transmission)
        end

        recv_parsed
      end

      private

      # Decode CoAP URIs.
      def decode_uri(uri)
        uri = CoAP.scheme_and_authority_decode(uri.to_s)

        @logger.debug 'URI decoded: ' + uri.inspect
        fail ArgumentError, 'Invalid URI' if uri.nil?

        scheme = uri.first
        if scheme == "coaps"
          self.use_dtls
        end

        uri.drop(1)
      end

      def initialize_message(method, path, query = nil, payload = nil)
        mid = SecureRandom.random_number(0xffff)

        options = {
          uri_path: CoAP.path_decode(path)
        }
        
        unless @options[:token] == false
          options[:token] = SecureRandom.random_number(0xffffffff)
        end

        unless query.nil?
          options[:uri_query] = CoAP.query_decode(query)
        end

        Message.new(:con, method, mid, payload, options)
      end

      # Log message to debug log.
      def log_message(text, message)
        @logger.debug '### ' + text.to_s.upcase.gsub('_', ' ')
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
