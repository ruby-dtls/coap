require 'coveralls'
Coveralls.wear_merged!

#$:.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'core'

require 'faker'

def fixture_path
  File.join(File.dirname(__FILE__), 'fixtures')
end

def fixture(name)
  File.read(File.join(fixture_path, name))
end

include CoRE::CoAP
