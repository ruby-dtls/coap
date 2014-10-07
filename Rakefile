require 'bundler/gem_tasks'
require 'coveralls/rake/task'
require 'rake/testtask'
require 'rspec/core/rake_task'

Coveralls::RakeTask.new

Rake::TestTask.new do |t|
  t.libs << 'test'
end

RSpec::Core::RakeTask.new(:spec)

desc 'Run tests.'
task default: [:spec, :test]

desc 'Tun tests and push coverage to coveralls.'
task coveralls: [:default, 'coveralls:push']
