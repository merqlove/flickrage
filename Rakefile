require 'bundler/gem_tasks'
require 'bundler/setup'

PROJECT_ROOT = File.expand_path('..', __FILE__)
$:.unshift "#{PROJECT_ROOT}/lib"

begin
  require 'rspec/core/rake_task'

  desc 'Run all specs'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # The test gem group fails to install on the platform for some reason
end

task default: :spec
