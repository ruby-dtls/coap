module CoRE
  module CoAP
    module Utility
      def empty_buffer
        String.new # Was: ''.encode(BIN)
      end

      def invert_into_hash(a)
        a.each_with_index.each_with_object({}) { |k, h| h[k[0]] = k[1] if k[0] }
      end

      def critical?(option)
        if oi = CoAP::OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option.odd?
      end

      def unsafe?(option)
        if oi = CoAP::OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option & 2 == 2
      end

      def no_cache_key?(option)
        if oi = CoAP::OPTIONS_I[option] # this is really an option name symbol
          option = oi[0]          # -> to option number
        end
        option & 0x1e == 0x1c
      end
    end
  end
end
