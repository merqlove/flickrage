# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Worker::Search do
  include_context 'environment'

  subject(:search) { described_class }

  describe 'with success work' do
    let(:keywords) { %w(one two) }

    before do
      Flickrage.configure do |config|
        config.dict = %w(oxcheek hierarchically unministerial invaried muletress marquisship angiotasis captaculum citreous
                         sportance cigarless)
        config.verbose = true
        config.max = 10
      end
    end

    it 'when found by all keywords' do
      stub_reflection
      (Flickrage.config.dict + keywords).each do |k|
        stub_search(k)
      end

      image_list = search.new(default_options_t.merge('keywords' => keywords)).call

      expect(image_list).not_to be_nil
      expect(image_list.size).to eq(10)
      expect(image_list.valid?).to be_truthy

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: hash_including(extras: 'url_m, url_z, url_c, url_l, url_o', sort: 'interestingness-desc')))
        .to have_been_made.times(10)
    end

    it 'when we try few more' do
      stub_reflection
      keywords = %w(one two three four)

      keys = (keywords[2..3] + Flickrage.config.dict)
      keys.each do |k|
        stub_search(k)
      end
      stub_search_fail(keywords[0])
      stub_search_fail(keywords[1])

      image_list = search.new(default_options_t.merge('keywords' => keywords)).call

      expect(image_list).not_to be_nil
      expect(image_list.size).to eq(10)
      expect(image_list.valid?).to be_truthy

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: hash_including(extras: 'url_m, url_z, url_c, url_l, url_o', sort: 'interestingness-desc')))
        .to have_been_made.times(12)
    end
  end

  describe 'with failed work' do
    let(:keywords) { %w(one two) }

    before do
      Flickrage.configure do |config|
        config.dict = %w(oxcheek hierarchically unministerial invaried muletress marquisship angiotasis captaculum citreous
                         sportance cigarless nonsubstantialist phallin annunciable burdenous dilater prewillingness
                         shepherdage preadditional Ranella unvindicated aeroplaner)
        config.max = 10
      end
    end

    it 'when nothing found' do
      stub_reflection
      (Flickrage.config.dict + keywords).each do |k|
        stub_search_fail(k)
      end

      expect { search.new(default_options_t.merge('keywords' => keywords)).call }
        .to raise_exception(Flickrage::SearchError)

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: hash_including(extras: 'url_m, url_z, url_c, url_l, url_o', sort: 'interestingness-desc')))
        .to have_been_made.times(20)
    end
  end
end
