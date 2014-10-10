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

require 'core/coap/utility'
require 'core/coap/codification'
require 'core/coap/types'
require 'core/coap/options'
require 'core/coap/registry'

require 'core/coap/coap'
require 'core/coap/message'
require 'core/coap/version'
require 'core/coap/block'
require 'core/coap/resolver'
require 'core/coap/ether'
require 'core/coap/observer'
require 'core/coap/client'
