# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Service::Search do
  include_context 'environment'

  let(:keyword) { 'test2' }
  let(:url_l)   { 'http://some.host.com/image.png' }

  subject(:search) { described_class }

  describe 'with success api' do
    it 'when find images' do
      stub_reflection
      stub_search(text)
      image = search.new.run(keyword)

      expect(image.keyword).to eq(keyword)
      expect(image.url).to eq(url_l)

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: search_request_body(text)))
        .to have_been_made
    end
  end

  describe 'with failed api' do
    it 'when miss images' do
      stub_reflection
      stub_search_fail(text)
      image = search.new.run(keyword)

      expect(image).to be_nil

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: search_request_body(text)))
        .to have_been_made
    end
  end
end
