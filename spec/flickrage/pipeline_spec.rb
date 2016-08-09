# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Pipeline do
  include_context 'environment'

  subject(:pipeline) { described_class }

  let(:keywords) { %w(one two) }

  let(:file) { file_path('image.jpg') }
  let(:resized_file) { file_path('resized.image.jpg') }
  let(:collage_file) { file_path('collage.image.10.jpg') }
  let(:width) { 200 }
  let(:height) { 200 }

  let(:file_name) { 'collage.image.jpg' }

  let(:dict) do
    %w(oxcheek hierarchically unministerial invaried muletress marquisship angiotasis captaculum citreous
       sportance cigarless)
  end

  let(:files) do
    (keywords + dict).map { |k| "#{k}.jpg" }
  end

  let(:resized_files) do
    files.map { |f| "resized.#{f}" }
  end

  let(:urls) do
    files.map { |f| url(f) }
  end

  before do
    remove_files('*.jpg')
    Flickrage.configure do |config|
      config.dict = dict

      config.output = "#{project_path}/tmp"
      config.max = 10
      config.verbose = false
      config.width = width
      config.height = height
    end
  end

  def url(image)
    "http://some.host.com/#{image}"
  end

  describe 'with success compose' do
    it 'when collage success' do
      stub_reflection
      (Flickrage.config.dict + keywords).each_with_index do |k, i|
        stub_search(k, req_url: urls[i])
        stub_image(urls[i], file)
      end

      image_list = pipeline.new(default_options_t.merge('file_name' => file_name, 'keywords' => keywords)).run
      expect(image_list.valid?).to be_truthy
      expect(image_list.composed?).to be_truthy
      expect(File.exist?(image_list.collage_path)).to be_truthy
      expect(image_list.collage_path).to be_same_file_as_lite(collage_file)

      image_list.downloaded.each do |image|
        expect(File.exist?(image.local_path)).to be_truthy
        expect(image.local_path).to be_same_file_as_lite(file)
        expect(a_request(:get, image.url))
          .to have_been_made
      end

      image_list.resized.each do |image|
        expect(File.exist?(image.resize_path)).to be_truthy
        expect(image.resize_path).to be_same_file_as_lite(resized_file)
      end

      expect(a_request(:post, api_url).with(body: reflection_request_body))
        .to have_been_made.at_least_times(0)
      expect(a_request(:post, api_url).with(body: hash_including(extras: 'url_m, url_z, url_c, url_l, url_o', sort: 'interestingness-desc')))
        .to have_been_made.times(10)
    end
  end

  describe 'with fail on something' do
    it 'when nothing resized raise' do
      stub_reflection
      (Flickrage.config.dict + keywords).each_with_index do |k, i|
        stub_search(k, req_url: urls[i])
        stub_image(urls[i], file)
      end

      expect { pipeline.new(default_options_t.merge('file_name' => nil, 'keywords' => keywords)).run }
        .to raise_exception(Flickrage::CollageError)
    end
  end
end
