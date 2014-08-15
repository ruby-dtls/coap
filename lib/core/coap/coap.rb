# coapmessage.rb
# Copyright (C) 2010..2013 Carsten Bormann <cabo@tzi.org>

module CoRE
  module CoAP
    # BIN = Encoding::BINARY
    # UTF8 = Encoding::UTF_8

    extend Utility

    include DeAndEncoding
    include Options

    EMPTY = empty_buffer.freeze

    TTYPES = [:con, :non, :ack, :rst]
    TTYPES_I = invert_into_hash(TTYPES)

    METHODS = [nil, :get, :post, :put, :delete]
    METHODS_I = invert_into_hash(METHODS)

    # Shortcut: CoRE::CoAP::parse == CoRE::CoAP::Message.parse
    def self.parse(*args)
      Message.parse(*args)
    end
  end
end
