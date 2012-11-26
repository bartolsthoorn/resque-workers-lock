require 'resque/tasks'

task "resque:setup" do
  require_relative 'test/lock_worker'
end

require 'rake/testtask'
require 'rdoc/task'
require 'resque/tasks'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
