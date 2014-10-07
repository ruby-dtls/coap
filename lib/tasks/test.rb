namespace :test do
  desc 'Run all test suites and push coverage data to Coveralls'
  task :coveralls do
    require 'coveralls'

    Rake::Task['spec'].invoke
    Rake::Task['test'].invoke

    Coveralls.push!
  end
end
