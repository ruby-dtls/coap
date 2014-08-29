require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec/core/rake_task'

require_relative 'lib/tasks/test'

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests.'
task default: [:spec, :test]
