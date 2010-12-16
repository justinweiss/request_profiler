require 'bundler'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task :default => :test
task :build => :test
task :release => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
