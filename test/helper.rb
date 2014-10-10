require 'coveralls'
Coveralls.wear_merged!

require 'minitest/autorun'
require 'logger'

$:.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'core'

d = ENV['DEBUG']
Log = Logger.new(d && IO.new(d.to_i))

Log.formatter = proc do |sev, time, prog, msg|
  "#{time.strftime('%Y%m%d%H%M%S')}(#{sev.downcase}) #{msg}\n"
end
