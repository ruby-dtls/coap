# coapmessage.rb
# Copyright (C) 2010..2013 Carsten Bormann <cabo@tzi.org>

module CoRE
  module CoAP
    BIN = Encoding::BINARY
    UTF8 = Encoding::UTF_8

    class << self
      def empty_buffer
        String.new  # was: ''.encode(BIN)
      end

      def invert_into_hash(a)
        a.each_with_index.each_with_object({}) { |k, h| h[k[0]] = k[1] if k[0] }
      end

      # Arrays that describe a specific option type:
      # [default value, length range, repeatable?, decoder, encoder]

      # we only care about presence or absence, always empty
      def presence_once
        [false, (0..0), false,
         ->(a) { true },
         ->(v) { v ? [""] : []}
        ]
      end

      # token-style, goedelized in o256 here
      def o256_once(min, max, default = nil)
        [default, (min..max), false,
         ->(a) { o256_decode(a[0]) },
         ->(v) { v == default ? [] : [o256_encode(v)] }
        ]
      end
      def o256_many(min, max)   # unused
        [nil, (min..max), true,
         ->(a) { a.map{ |x| o256_decode(x)} },
         ->(v) { Array(v).map{ |x| o256_encode(x)} }
        ]
      end

      # vlb as in core-coap Annex A
      def uint_once(min, max, default = nil)
        [default, (min..max), false,
         ->(a) { vlb_decode(a[0]) },
         ->(v) { v == default ? [] : [vlb_encode(v)] }
        ]
      end
      def uint_many(min, max)
        [nil, (min..max), true,
         ->(a) { a.map{ |x| vlb_decode(x)} },
         ->(v) { Array(v).map{ |x| vlb_encode(x)} }
        ]
      end

      # Any other opaque byte sequence
      def opaq_once(min, max, default = nil)
        [default, (min..max), false,
         ->(a) { a[0] },
         ->(v) { v == default ? [] : Array(v) }
        ]
      end
      def opaq_many(min, max)
        [nil, (min..max), true,
         ->(a) { a },
         ->(v) { Array(v) }
        ]
      end

      #same, but interpreted as UTF-8
      def str_once(min, max, default = nil)
        [default, (min..max), false,
         ->(a) { a[0].force_encoding('utf-8') }, # XXX needed?
         ->(v) { v == default ? [] : Array(v) }
        ]
      end
      def str_many(min, max)
        [nil, (min..max), true,
         ->(a) { a.map { |s| s.force_encoding('utf-8')} }, # XXX needed?
         ->(v) { Array(v) }
        ]
      end
    end

    EMPTY = empty_buffer.freeze

    TTYPES = [:con, :non, :ack, :rst]
    TTYPES_I = invert_into_hash(TTYPES)
    METHODS = [nil, :get, :post, :put, :delete]
    METHODS_I = invert_into_hash(METHODS)

    # for now, keep 19
#   TOKEN_ON = -1             # handled specially
    TOKEN_ON = 19

    # 14 => :user, default, length range, replicable?, decoder, encoder
    OPTIONS = { # name      minlength, maxlength, [default]    defined where:
      1 =>   [:if_match,       *o256_many(0, 8)],        # core-coap-12
      3 =>   [:uri_host,       *str_once(1, 255)],       # core-coap-12
      4 =>   [:etag,           *o256_many(1, 8)],        # core-coap-12 !! once in rp
      5 =>   [:if_none_match,  *presence_once],          # core-coap-12
      6 =>   [:observe,        *uint_once(0, 3)],        # core-observe-07
      7 =>   [:uri_port,       *uint_once(0, 2)],        # core-coap-12
      8 =>   [:location_path,  *str_many(0, 255)],       # core-coap-12
      11 =>  [:uri_path,       *str_many(0, 255)],       # core-coap-12
      12 =>  [:content_format, *uint_once(0, 2)],        # core-coap-12
      14 =>  [:max_age,        *uint_once(0, 4, 60)],    # core-coap-12
      15 =>  [:uri_query,      *str_many(0, 255)],       # core-coap-12
      17 =>  [:accept,         *uint_once(0, 2)],        # core-coap-18!
      TOKEN_ON =>  [:token,    *o256_once(1, 8, 0)],     # core-coap-12 -> opaq_once(1, 8, EMPTY)
      20 =>  [:location_query, *str_many(0, 255)],       # core-coap-12
      23 =>  [:block2,         *uint_once(0, 3)],        # core-block-10
      27 =>  [:block1,         *uint_once(0, 3)],        # core-block-10
      28 =>  [:size2,          *uint_once(0, 4)],        # core-block-10
      35 =>  [:proxy_uri,      *str_once(1, 1034)],      # core-coap-12
      39 =>  [:proxy_scheme,   *str_once(1, 255)],       # core-coap-13
      60 =>  [:size1,          *uint_once(0, 4)],        # core-block-10
    }
    # :user => 14, :user, def, range, rep, deco, enco
    OPTIONS_I = Hash[OPTIONS.map { |k, v| [v[0], [k, *v]] }]
    DEFAULTING_OPTIONS = Hash[OPTIONS.map { |k, v| [v[0].freeze, v[1].freeze]}
                              .select{ |k, v| v} ].freeze

    class << self
      def critical?(option)
        if oi = OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option.odd?
      end

      def unsafe?(option)
        if oi = OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option & 2 == 2
      end

      def no_cache_key?(option)
        if oi = OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option & 0x1e == 0x1c
      end

      # The variable-length binary (vlb) numbers defined in CoRE-CoAP Appendix A.
      def vlb_encode n
        # on = n
        n = Integer(n)
        raise ArgumentError, "Can't encode negative number #{n}" if n < 0
        v = empty_buffer
        while n > 0
          v << (n & 0xFF)
          n >>= 8
        end
        v.reverse!
        # warn "Encoded #{on} as #{v.inspect}"
        v
      end

      def vlb_decode s
        n = 0
        s.each_byte { |b| n <<= 8; n += b}
        n
      end

      # byte strings lexicographically goedelized as numbers (one+256 coding)
      def o256_encode(num)
        str = empty_buffer
        while num > 0
          num -= 1
          str << (num & 0xFF)
          num >>= 8
        end
        str.reverse
      end

      def o256_decode(str)
        num = 0
        str.each_byte do |b|
          num <<= 8
          num += b + 1
        end
        num
      end

      # n must be 2**k
      # returns k
      def number_of_bits_up_to(n)
        Math.frexp(n-1)[1]
      end

      def scheme_and_authority_encode(host, port)
        unless host =~ /\[.*\]/
          host = "[#{host}]" if host =~ /:/
        end
        scheme_and_authority = "coap://#{host}"
        port = Integer(port)
        scheme_and_authority << ":#{port}" unless port == 5683
        scheme_and_authority
      end

      def scheme_and_authority_decode(s)
        if s =~ %r{\A(?:coap://)((?:\[|%5B)([^\]]*)(?:\]|%5D)|([^:/]*))(:(\d+))?(/.*)?\z}i
          host = $2 || $3       # should check syntax...
          port = $5 || 5683
          [host, port.to_i, $6]
        end
      end

      UNRESERVED = "A-Za-z0-9\\-\\._~" # ALPHA / DIGIT / "-" / "." / "_" / "~"
      SUB_DELIM = "!$&'()*+,;=" # "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
      PATH_UNENCODED = "#{UNRESERVED}#{SUB_DELIM}:@"
      PATH_ENCODED_RE = /[^#{PATH_UNENCODED}]/mn
      def path_encode(uri_elements)
        "/" << uri_elements.map { |el|
          el.dup.force_encoding(BIN).gsub(PATH_ENCODED_RE) { |x| "%%%02X" % x.ord }
        }.join("/")
      end

      SUB_DELIM_NO_AMP = SUB_DELIM.gsub("&", "")
      QUERY_UNENCODED = "#{UNRESERVED}#{SUB_DELIM_NO_AMP}:@/?"
      QUERY_ENCODED_RE = /[^#{QUERY_UNENCODED}]/mn
      def query_encode(query_elements)
        if query_elements.empty?
          ""
        else
          "?" << query_elements.map { |el|
            el.dup.force_encoding(BIN).gsub(QUERY_ENCODED_RE) { |x| "%%%02X" % x.ord }
          }.join("&")
        end
      end

      def percent_decode(el)
          el.gsub(/%(..)/) { $1.to_i(16).chr(BIN)}.force_encoding(UTF8)
      end

      def path_decode(path)
        a = path.split("/", -1)     # needs -1 to avoid eating trailing slashes!
        return a if a.empty?
        raise ArgumentError, "path #{path.inspect} did not start with /" unless a[0] == ""
        return [] if a[1] == '' # special case for "/"
        a[1..-1].map { |el|
          percent_decode(el)
        }
      end

      def query_decode(query)
        return [] if query.empty?
        raise ArgumentError, "query #{query.inspect} did not start with ?" unless query[0] == "?"
        a = query.split("&", -1).map { |el|
          el.gsub(/%(..)/) { $1.to_i(16).chr(BIN)}.force_encoding(UTF8)
        }
        a[0] = a[0][1..-1]      # remove "?"
        a
      end

      # Shortcut: CoRE::CoAP::parse == CoRE::CoAP::Message.parse
      def parse(*args)
        Message.parse(*args)
      end
    end

    class Message < Struct.new(:ver, :tt, :mcode, :mid, :options, :payload)
      def initialize(*args) # convenience: .new(tt?, mcode?, mid?, payload?, hash?)
        if args.size < 6
          h = {}
          h = args.pop.dup if args.last.is_a? Hash
          tt = h.delete(:tt) || args.shift
          mcode = h.delete(:mcode) || args.shift
          case mcode
            when Integer; mcode = METHODS[mcode] || [mcode >> 5, mcode & 0x1f]
            when Float; mcode = [mcode.to_i, (mcode * 100 % 100).round] # accept 2.05 and such
          end
          mid = h.delete(:mid) || args.shift
          payload = h.delete(:payload) || args.shift || EMPTY # no payload = empty payload
          raise "CoRE::CoAP::Message.new: hash or all args" unless args.empty?
          super(1, tt, mcode, mid, h, payload)
        else
          super
        end
      end
      def mcode_readable
        case mcode
        when Array
          "#{mcode[0]}.#{"%02d" % mcode[1]}"
        else
          mcode.to_s
        end
      end

      def self.deklausify(d, dpos, len)
        case len
        when 0..12
          [len, dpos]
        when 13
          [d.getbyte(dpos) + 13, dpos += 1]
        when 14
          [d.byteslice(dpos, 2).unpack("n")[0] + 269, dpos += 2]
        else
          raise "[#{d.inspect}] Bad delta/length nibble #{len} at #{dpos}"
        end
      end
      
      def self.parse(d)
        # dpos keeps our current position in parsing d
        b1, mcode, mid = d.unpack("CCn"); dpos = 4
        toklen = b1 & 0xf
        token = d.byteslice(dpos, toklen); dpos += toklen
        b1 >>= 4
        tt = TTYPES[b1 & 0x3]
        b1 >>= 2
        raise ArgumentError, "unknown CoAP version #{b1}" unless b1 == 1
        mcode = METHODS[mcode] || [mcode>>5, mcode&0x1F]

        # collect options
        onumber = 0             # current option number
        options = Hash.new { |h, k| h[k] = [] }
        dlen = d.bytesize
        while dpos < dlen
          tl1 = d.getbyte(dpos); dpos += 1
          raise ArgumentError, "option is not there at #{dpos} with oc #{orig_numopt}" unless tl1 # XXX

          break if tl1 == 0xff

          odelta, dpos = deklausify(d, dpos, tl1 >> 4)
          olen, dpos = deklausify(d, dpos, tl1 & 0xF)

          onumber += odelta

          if dpos + olen > dlen
            raise ArgumentError, "#{olen}-byte option at #{dpos} -- not enough data in #{dlen} total"
          end

          oval = d.byteslice(dpos, olen); dpos += olen
          options[onumber] << oval
        end

        options[TOKEN_ON] = [token] if token != ''
        
        # d.bytesize = more than all the rest...
        decode_options_and_put_together(b1, tt, mcode, mid, options,
                                        d.byteslice(dpos, d.bytesize))
      end

      def self.decode_options_and_put_together(b1, tt, mcode, mid, options, payload)
        # check and decode option values
        decoded_options = DEFAULTING_OPTIONS.dup
        options.each_pair do |k, v|
          if oinfo = OPTIONS[k]
            oname, _, minmax, repeatable, decoder, _ = *oinfo
            repeatable or v.size <= 1 or
              raise ArgumentError, "repeated unrepeatable option #{oname}"
            v.each do |v1|
              unless minmax === v1.bytesize
                raise ArgumentError, "#{v1.inspect} out of #{minmax} for #{oname}"
              end
            end
            decoded_options[oname] = decoder.call(v)
          else
            decoded_options[k] = v # we don't know what that is -- keep it in raw
          end
        end

        new(b1, tt, mcode, mid, Hash[decoded_options], payload) # XXX: why Hash[] again?
      end

      def prepare_options
        prepared_options = {}
        options.each do |k, v|
          # puts "k = #{k.inspect}, oinfo_i = #{OPTIONS_I[k].inspect}"
          if oinfo_i = OPTIONS_I[k]
            onum, oname, defv, minmax, rep, _, encoder = *oinfo_i
            prepared_options[onum] = a = encoder.call(v)
            rep or a.size <= 1 or raise "repeated option #{oname} #{a.inspect}"
            a.each do |v1|
              unless minmax === v1.bytesize
                raise ArgumentError, "#{v1.inspect} out of #{minmax} for #{oname}"
              end
            end
          else
            raise ArgumentError, "#{k.inspect}: unknown option" unless Integer === k
            prepared_options[k] = Array(v) # store raw option
          end
        end
        prepared_options
      end

      def klausify(n)
        if n < 13
          [n, '']
        else
          n -= 13
          if n < 256
            [13, [n].pack("C")]
          else
            [14, [n-256].pack("n")]
          end
        end
      end

      def to_wire

        # check and encode option values
        prepared_options = prepare_options
        # puts "prepared_options: #{prepared_options}"

        token = (prepared_options.delete(TOKEN_ON) || [nil])[0] || ''
        puts "TOKEN: #{token.inspect}" unless token

        b1 = 0x40 | TTYPES_I[tt] << 4 | token.bytesize
        b2 = METHODS_I[mcode] || (mcode[0] << 5) + mcode[1]
        result = [b1, b2, mid].pack("CCn")
        result << token

        # stuff options in packet
        onumber = 0
        num_encoded_options = 0
        prepared_options.keys.sort.each do |k|
          raise "Bad Option Type #{k.inspect}" unless Integer === k && k >= 0
          a = prepared_options[k]
          a.each do |v|
            # result << frob(k, v)
            odelta = k - onumber
            onumber = k

            odelta1, odelta2 = klausify(odelta)
            odelta1 <<= 4

            length1, length2 = klausify(v.bytesize)
            result << [odelta1 | length1].pack("C")
            result << odelta2
            result << length2
            result << v.dup.force_encoding(BIN)         # value
          end
        end

        if payload != ''
          result << 0xFF
          result << payload.dup.force_encoding(BIN)
        end
        result
      end

    end
  end
end
