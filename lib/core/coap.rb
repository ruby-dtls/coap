module CoRE
  module CoAP
    module_function

    def logger
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::WARN
      end

      @logger
    end

    def logger=(logger)
      @logger.close unless @logger.nil?
      @logger = logger
    end
  end
end

require 'celluloid/io'
require 'ipaddr'
require 'logger'
require 'resolv-ipv6favor'
require 'socket'
require 'timeout'
require 'yaml'

require_relative 'hexdump'

require_relative 'coap/utility'
require_relative 'coap/codification'
require_relative 'coap/types'
require_relative 'coap/options'
require_relative 'coap/registry'

require_relative 'coap/coap'
require_relative 'coap/message'
require_relative 'coap/version'
require_relative 'coap/block'
require_relative 'coap/resolver'
require_relative 'coap/ether'
require_relative 'coap/observer'
require_relative 'coap/client'
