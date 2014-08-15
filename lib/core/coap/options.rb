module CoRE
  module CoAP
    module Options
      extend Types

      TOKEN_ON = 19

      # 14 => :user, default, length range, replicable?, decoder, encoder
      OPTIONS = { # name      minlength, maxlength, [default]    defined where:
         1 => [:if_match,       *o256_many(0, 8)],     # core-coap-12
         3 => [:uri_host,       *str_once(1, 255)],    # core-coap-12
         4 => [:etag,           *o256_many(1, 8)],     # core-coap-12 !! once in rp
         5 => [:if_none_match,  *presence_once],       # core-coap-12
         6 => [:observe,        *uint_once(0, 3)],     # core-observe-07
         7 => [:uri_port,       *uint_once(0, 2)],     # core-coap-12
         8 => [:location_path,  *str_many(0, 255)],    # core-coap-12
        11 => [:uri_path,       *str_many(0, 255)],    # core-coap-12
        12 => [:content_format, *uint_once(0, 2)],     # core-coap-12
        14 => [:max_age,        *uint_once(0, 4, 60)], # core-coap-12
        15 => [:uri_query,      *str_many(0, 255)],    # core-coap-12
        17 => [:accept,         *uint_once(0, 2)],     # core-coap-18!
        TOKEN_ON => [:token,    *o256_once(1, 8, 0)],  # core-coap-12 -> opaq_once(1, 8, EMPTY)
        20 => [:location_query, *str_many(0, 255)],    # core-coap-12
        23 => [:block2,         *uint_once(0, 3)],     # core-block-10
        27 => [:block1,         *uint_once(0, 3)],     # core-block-10
        28 => [:size2,          *uint_once(0, 4)],     # core-block-10
        35 => [:proxy_uri,      *str_once(1, 1034)],   # core-coap-12
        39 => [:proxy_scheme,   *str_once(1, 255)],    # core-coap-13
        60 => [:size1,          *uint_once(0, 4)],     # core-block-10
      }

      # :user => 14, :user, def, range, rep, deco, enco
      OPTIONS_I =
        Hash[OPTIONS.map { |k, v| [v[0], [k, *v]] }]

      DEFAULTING_OPTIONS = 
        Hash[
          OPTIONS 
            .map { |k, v| [v[0].freeze, v[1].freeze] }
            .select { |k, v| v }
        ].freeze
    end
  end
end
