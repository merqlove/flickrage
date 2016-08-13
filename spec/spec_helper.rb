# frozen_string_literal: true
require 'coveralls'
Coveralls.wear! do
  add_filter '/spec/*'
end

require 'bundler'
Bundler.setup

require 'flickrage/cli'
require 'webmock/rspec'
require 'fileutils'
require 'mini_magick'
require_relative 'shared/environment'

WebMock.disable_net_connect!(allow_localhost: true)
WebMock.disable!(except: [:net_http])

Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).each { |f| require_relative f }

RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.disable_monkey_patching!

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

def project_path
  File.expand_path('../..', __FILE__)
end

def fixture(fixture_name)
  Pathname.new(project_path + '/spec/fixtures/flickr/').join("#{fixture_name}.json").read
end

def file_path(name)
  Pathname.new(project_path + '/spec/fixtures/').join(name.to_s)
end

def file_read(name)
  file_path(name).read
end

def remove_files(mask = '*.jpg')
  FileUtils.rm Dir.glob("#{project_path}/tmp/#{mask}"), force: true
end

def remove_file(name = 'image.jpg')
  FileUtils.remove_file("#{project_path}/tmp/#{name}", true)
end
