# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Log do
  include_context 'environment'

  subject(:log) { described_class }

  describe 'will have message' do
    it('#info')  { logger_respond_to(:info)  }
    it('#debug') { logger_respond_to(:debug) }
    it('#warn')  { logger_respond_to(:warn)  }
    it('#fatal') { logger_respond_to(:fatal) }
    it('#error') { logger_respond_to(:error) }

    it '#blablabla' do
      expect(Flickrage.logger).not_to respond_to(:blablabla)
    end

    before :each do
      Flickrage.configure do |config|
        config.logger = Logger.new(log_path)
        config.verbose = true
        config.quiet = true
      end
      Flickrage.logger = Flickrage::Log.new
    end

    def logger_respond_to(type)
      expect(Flickrage.logger).to respond_to(type)
      Flickrage.logger.send(type, 'fff')
      expect(Flickrage.logger.buffer).to include('fff')
    end
  end

  describe 'will work with files' do
    it 'with file' do
      FileUtils.remove_file(log_path, true)

      Flickrage.configure do |config|
        config.logger = Logger.new(log_path)
        config.verbose = true
        config.quiet = true
      end
      Flickrage.logger = Flickrage::Log.new

      expect(File.exist?(log_path)).to be_truthy
    end

    it 'with no file' do
      FileUtils.remove_file(log_path, true)

      Flickrage.logger = Flickrage::Log.new

      expect(File.exist?(log_path)).to be_falsey
    end

    it 'with no file but logging' do
      FileUtils.remove_file(log_path, true)

      Flickrage.logger = Flickrage::Log.new

      expect(File.exist?(log_path)).to be_falsey

      expect(Flickrage.logger).to respond_to(:info)
      Flickrage.logger.info('fff')
      expect(Flickrage.logger.buffer).to include('fff')
    end
  end

  describe '#print_table' do
    it 'output table to file' do
      FileUtils.remove_file(log_path, true)

      Flickrage.configure do |config|
        config.logger = Logger.new(log_path)
        config.verbose = true
        config.quiet = true
      end
      Flickrage.logger = Flickrage::Log.new

      expect { Flickrage.logger.print_table([%w(keywords name), %w(a b c)]) }.not_to output('keywords name').to_stdout
      expect(File.readlines(log_path)[1]).to include('["keywords", "name"]')
      expect(File.readlines(log_path)[2]).to include('["a", "b", "c"]')
    end
  end
end
