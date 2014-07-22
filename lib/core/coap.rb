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

    def logger= logger
      @logger.close unless @logger.nil?
      
      @logger = logger
    end
  end
end

require 'logger'
require 'socket'
require 'resolv-ipv6favor'
require 'ipaddr'
require 'timeout'
#require 'CoDTLS'

require_relative 'coap/coap.rb'
require_relative 'coap/message.rb'
require_relative 'coap/version.rb'
require_relative 'coap/block.rb'
require_relative 'coap/mysocket.rb'
require_relative 'coap/observer.rb'
require_relative 'coap/client.rb'

=begin
require 'coap/coap.rb'
require 'coap/message.rb'
require 'coap/version.rb'
require 'coap/block.rb'
require 'coap/mysocket.rb'
require 'coap/observer.rb'
require 'coap/client.rb'
=end
