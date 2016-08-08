# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Service::Downloader do
  include_context 'environment'

  subject(:download) { described_class }

  before do
    remove_file('image.jpg')
    Flickrage.configure do |config|
      config.output = "#{project_path}/tmp"
    end
  end

  let(:file) { file_path('image.jpg') }
  let(:url_l) { 'http://some.host.com/image.jpg' }

  let(:image) { Flickrage::Entity::Image.new(url: url_l, keyword: keyword, id: id, width: width_l, height: height_l, title: title) }

  describe 'with success download' do
    it 'when find images' do
      stub_image(url_l, file)

      new_image = download.new.run(image)

      expect(new_image.downloaded?).to be_truthy
      expect(File.exist?(new_image.local_path)).to be_truthy
      expect(new_image.local_path).to be_same_file_as_lite(file)

      expect(a_request(:get, url_l))
        .to have_been_made
    end
  end

  describe 'with failed download' do
    it 'when loose images' do
      stub_image(url_l, 'Not Found', 404)

      new_image = download.new.run(image)

      expect(new_image).not_to be_nil
      expect(new_image.downloaded?).to be_falsey
      expect(File.exist?(new_image.local_path)).to be_falsey

      expect(a_request(:get, url_l))
        .to have_been_made
    end
  end
end
