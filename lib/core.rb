$:.unshift File.expand_path(File.dirname(__FILE__))

module CoRE
end

require 'core/link'
require 'core/coap'
require 'core/hexdump'
require 'core/os'

require 'core/core_ext/socket'
