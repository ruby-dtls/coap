require_relative '../lib/core'

require 'faker'

def fixture_path
  File.join(File.dirname(__FILE__), 'fixtures')
end

def fixture(name)
  File.read(File.join(fixture_path, name))
end
