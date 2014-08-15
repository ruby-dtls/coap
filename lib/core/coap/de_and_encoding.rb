# coapmessage.rb
# Copyright (C) 2010..2013 Carsten Bormann <cabo@tzi.org>

module CoRE
  module CoAP
    module DeAndEncoding
      BIN = Encoding::BINARY
      UTF8 = Encoding::UTF_8

      # Also extend on include.
      def self.included(base)
        base.send :extend, DeAndEncoding
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
        '/' + uri_elements.map { |el| uri_encode_element(el, PATH_ENCODED_RE) }.join('/')
      end

      SUB_DELIM_NO_AMP = SUB_DELIM.gsub("&", "")
      QUERY_UNENCODED = "#{UNRESERVED}#{SUB_DELIM_NO_AMP}:@/?"
      QUERY_ENCODED_RE = /[^#{QUERY_UNENCODED}]/mn
      def query_encode(query_elements)
        return '' if query_elements.empty?
        '?' + query_elements.map { |el| uri_encode_element(el, QUERY_ENCODED_RE) }.join('&')
      end

      def uri_encode_element(el, re)
        el.dup.force_encoding(BIN).gsub(re) { |x| "%%%02X" % x.ord }
      end

      def percent_decode(el)
        el.gsub(/%(..)/) { $1.to_i(16).chr(BIN) }.force_encoding(UTF8)
      end

      def path_decode(path)
        # Needs -1 to avoid eating trailing slashes!
        a = path.split('/', -1) 

        return a if a.empty?

        if a[0] != ''
          raise ArgumentError, "Path #{path.inspect} not starting with /"
        end

        # Special case for "/"
        return [] if a[1] == '' 

        a[1..-1].map { |el| percent_decode(el) }
      end

      def query_decode(query)
        return [] if query.empty?
        raise ArgumentError, "query #{query.inspect} did not start with ?" unless query[0] == "?"
        a = query.split("&", -1).map { |el|
          el.gsub(/%(..)/) { $1.to_i(16).chr(BIN) }.force_encoding(UTF8)
        }
        a[0] = a[0][1..-1]      # remove "?"
        a
      end
    end
  end
end
