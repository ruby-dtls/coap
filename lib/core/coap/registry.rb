module CoRE
  module CoAP
    module Registry
      REGISTRY_PATH = File.join(File.dirname(__FILE__), 'registry').freeze

      def self.load_yaml(registry)
        registry = "#{registry}.yml"
        YAML.load_file(File.join(REGISTRY_PATH, registry))
      end

      CONTENT_FORMATS = load_yaml(:content_formats).freeze
      CONTENT_FORMATS_INVERTED = CONTENT_FORMATS.invert.freeze

      def self.convert_content_format(string_or_integer)
        if string_or_integer.is_a? String
          CONTENT_FORMATS_INVERTED[string_or_integer]
        else
          CONTENT_FORMATS[string_or_integer]
        end
      end
    end
  end
end
