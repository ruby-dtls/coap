# encoding: utf-8

module CoRE
  # Implements CoRE Link Format (RFC6690)
  # http://tools.ietf.org/html/rfc6690
  # TODO Handle repeated attributes
  class Link
    VALID_ATTRS = [
      :anchor, :ct, :exp, :hreflang, :if, :ins, :media, :obs, :rt, :rel, :rev,
      :sz, :title, :type
    ]

    attr_accessor :uri

    def initialize(uri, attrs = {})
      @uri = uri || raise(ArgumentError.new('URI can not be unset.'))
      @attrs = attrs

      validate_attrs!(@attrs)
    end

    def merge!(hash)
      a = @attrs.merge(hash)
      validate_attrs!(a)
      @attrs = a
    end

    def method_missing(symbol, *args)
      attr = symbol.to_s.delete('=').to_sym

      if !VALID_ATTRS.include?(attr)
        raise ArgumentError.new("Invalid attribute «#{attr}».")
      end

      if symbol[-1] == '='
        @attrs[attr] = args.first.to_s
      else
        @attrs[attr]
      end
    end

    def to_s
      s = "<#{@uri}>"

      @attrs.sort.each do |attr, value|
        s += ";#{attr}=\"#{value}\""
      end

      s
    end

    def self.parse(data)
      parts = data.split(';')

      uri = parts.shift
      uri = uri.match(/\A\<(.+)\>\z/)

      if uri.nil?
        raise ArgumentError.new("Invalid URI in '#{data}'.")
      end

      link = Link.new(uri[1])

      parts.each do |part|
        attr, value = part.split('=')

        attr  = (attr + '=').to_sym
        value = value.delete('"')

        link.send(attr, value)
      end

      link
    end

    # TODO Handle misplaced commas
    def self.parse_multiple(data)
      results = []

      data.split(',').each do |part|
        results << self.parse(part)
      end

      results
    end

    private

    def validate_attrs!(attrs)
      if (VALID_ATTRS | attrs.keys).size > VALID_ATTRS.size
        invalid = (VALID_ATTRS | attrs.keys) - VALID_ATTRS
        raise ArgumentError.new("Invalid attributes: #{invalid.join(', ')}.")
      end
    end
  end
end
