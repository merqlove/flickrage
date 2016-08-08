# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage do
  include_context 'environment'

  describe Flickrage::SystemTimeout do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(Flickrage.logger.buffer)
        .to include 'Timeout, something going wrong...'
    end
  end

  describe Flickrage::PathError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(Flickrage.logger.buffer)
        .to include 'Please provide existing output path...'
    end
  end

  describe Flickrage::FileNameError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(Flickrage.logger.buffer)
        .to include 'Please provide right file_name...'
    end
  end

  describe Flickrage::DictError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(Flickrage.logger.buffer)
        .to include 'Please provide existing path to the dict...'
    end
  end

  describe Flickrage::NumberError do
    subject(:error) { described_class }

    it 'should be' do
      error.new('1 - 4')
      expect(Flickrage.logger.buffer)
        .to include 'Flickrage support for dimensions only numbers in range: 1 - 4...'
    end
  end

  describe Flickrage::SearchError do
    subject(:error) { described_class }

    it 'should work' do
      error.new('abcd')
      expect(Flickrage.logger.buffer)
        .to include 'Cannot find something...: abcd'
    end
  end

  describe Flickrage::DownloadError do
    subject(:error) { described_class }

    it 'should work' do
      error.new('abcd')
      expect(Flickrage.logger.buffer)
        .to include 'Connection is down or something goes wrong...: abcd'
    end
  end

  describe Flickrage::NoKeysError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(Flickrage.logger.buffer)
        .to include 'Please enter Flickr keys'
    end
  end

  describe Flickrage::SaveError do
    subject(:error) { described_class }

    it 'should work' do
      error.new('abcd')
      expect(Flickrage.logger.buffer)
        .to include 'Something wrong with output path: abcd'
    end
  end

  describe Flickrage::ResizeError do
    subject(:error) { described_class }

    it 'should work' do
      error.new('abcd')
      expect(Flickrage.logger.buffer)
        .to include 'Something wrong with resize tools: abcd'
    end
  end

  describe Flickrage::CollageError do
    subject(:error) { described_class }

    it 'should work' do
      error.new('abcd')
      expect(Flickrage.logger.buffer)
        .to include 'Something wrong with collage tools: abcd'
    end
  end
end
