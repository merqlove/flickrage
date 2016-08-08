# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_context 'environment' do
  let(:api_key)             { 'bar' }
  let(:shared_secret)       { 'somesecret' }
  let(:title)               { 'test title' }
  let(:keyword)             { 'test' }
  let(:width)               { 250 }
  let(:height)              { 150 }
  let(:width_l)             { 1000 }
  let(:height_l)            { 800 }
  let(:text)                { keyword }
  let(:url_l)               { 'http://some.host.com/image.jpg' }
  let(:image_file_name)     { 'image.jpg' }
  let(:file_name)           { 'collage.image.jpg' }
  let(:id)                  { '434333531234' }
  let(:cli_env_nil)         { Hash['FLICKR_API_KEY' => nil, 'FLICKR_SHARED_SECRET' => nil] }
  let(:cli_keys)            { Thor::CoreExt::HashWithIndifferentAccess.new(flickr_api_key: api_key) }
  let(:cli_keys_other)      { Thor::CoreExt::HashWithIndifferentAccess.new(flickr_shared_secret: 'NOSECRET') }
  let(:default_options) do
    Hash[width: 100, height: 100, keywords: %w(some great words), max: 10, file_name: 'test_collage.jpg',
         output: "#{project_path}/tmp", verbose: true, quiet: false, cleanup: true]
  end
  let(:default_options_t)   { Thor::CoreExt::HashWithIndifferentAccess.new(default_options) }
  let(:log_path)            { "#{project_path}/log/test.log" }
  let(:log)                 { Thor::CoreExt::HashWithIndifferentAccess.new(log: log_path) }

  let(:api_url)             { 'https://api.flickr.com/services/rest/' }
  let(:reflection_request_body) { { format: 'json', method: 'flickr.reflection.getMethods', nojsoncallback: '1' } }

  def copy_image(src_name = image_file_name, dest_name = image_file_name)
    FileUtils.copy("#{project_path}/spec/fixtures/#{src_name}", "#{project_path}/tmp/#{dest_name}")
  end

  def reset_api_keys
    ENV['FLICKR_API_KEY'] = nil
    ENV['FLICKR_SHARED_SECRET'] = nil
  end

  def set_api_keys
    ENV['FLICKR_API_KEY'] = api_key
    ENV['FLICKR_SHARED_SECRET'] = shared_secret
  end

  def setup_flickraw
    FlickRaw.api_key       = ENV['FLICKR_API_KEY']
    FlickRaw.shared_secret = ENV['FLICKR_SHARED_SECRET']
  end

  def reset_singletons
    Flickrage.configure do |config|
      config.verbose = false
      config.quiet = true
    end
    Flickrage.logger = Flickrage::Log.new
  end

  def stub_image(url = url_l, file = file_path('image.jpg'), status = 200)
    stub_request(:get, url)
      .to_return(status: status, body: file)
  end

  def stub_reflection(response_body = fixture('reflection.getMethods'), status = 200)
    stub_request(:post, api_url)
      .with(body: reflection_request_body)
      .to_return(status: status, body: response_body, headers: {})
  end

  def stub_search(req_text = text, *args)
    stub_request(:post, api_url)
      .with(body: search_request_body(req_text))
      .to_return(status: 200, body: search_response_body(*args), headers: {})
  end

  def stub_search_fail(req_text = text)
    stub_request(:post, api_url)
      .with(body: search_request_body(req_text))
      .to_return(status: 200, body: fixture('photos.search.empty'), headers: {})
  end

  def search_request_body(req_text = text)
    { content_type: '1', extras: 'url_l', format: 'json', method: 'flickr.photos.search',
      nojsoncallback: '1', pages: '1', per_page: '1', sort: 'interestingness-desc', text: req_text }
  end

  def search_response_body(req_url: url_l, req_id: id, req_title: title, req_width: width_l, req_height: height_l)
    body = fixture('photos.search')
    replacements = {
      url: req_url,
      id: req_id,
      title: req_title,
      width: req_width,
      height: req_height
    }
    replacements.each { |k, v| body.gsub!("%#{k}%", v.to_s) }
    body
  end

  before(:all) do
    WebMock.reset!
  end

  before(:each) do
    set_api_keys
    setup_flickraw
    reset_singletons
  end
end
