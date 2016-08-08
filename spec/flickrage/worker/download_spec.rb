# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Worker::Download do
  include_context 'environment'

  subject(:download) { described_class }

  let(:file) { file_path('image.jpg') }

  def url(image)
    "http://some.host.com/#{image}"
  end

  def image(file_name)
    Flickrage::Entity::Image.new(url: url(file_name), keyword: keyword, id: id, width: width_l,
                                 height: height_l, title: title, file_name: file_name)
  end

  def image_list(images)
    Flickrage::Entity::ImageList.new(images: images, total: images.size)
  end

  let(:images) do
    (1..19).map { |i| image("image#{i}.jpg") } + [image('image.jpg')]
  end

  before do
    remove_files('*.jpg')
    Flickrage.configure do |config|
      config.output = "#{project_path}/tmp"
      config.max = 20
      config.verbose = false
    end
  end

  describe 'with success' do
    it 'when found by all keywords' do
      image_list = image_list(images)
      image_list.images.each do |image|
        stub_image(image.url, file)
      end

      new_image_list = download.new(default_options_t).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.size).to eq(20)
      expect(new_image_list.valid?).to be_truthy

      new_image_list.images.each do |image|
        expect(image.downloaded?).to be_truthy
        expect(File.exist?(image.local_path)).to be_truthy
        expect(image.local_path).to be_same_file_as_lite(file)
        expect(a_request(:get, image.url))
          .to have_been_made
      end
    end

    it 'when partial found' do
      image_list = image_list(images)
      image_list.images[0..9].each do |image|
        stub_image(image.url, 'Not Found', 404)
      end
      image_list.images[10..19].each do |image|
        stub_image(image.url, file)
      end

      new_image_list = download.new(default_options_t).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.size).to eq(20)
      expect(new_image_list.valid?).to be_truthy

      new_image_list.images[0..9].each do |image|
        expect(image.downloaded?).to be_falsey
        expect(File.exist?(image.local_path)).to be_falsey
      end

      new_image_list.images[10..19].each do |image|
        expect(image.downloaded?).to be_truthy
        expect(File.exist?(image.local_path)).to be_truthy
        expect(image.local_path).to be_same_file_as_lite(file)
      end

      new_image_list.images.each do |image|
        expect(a_request(:get, image.url))
          .to have_been_made
      end
    end
  end

  describe 'with fail' do
    it 'when nothing found raise' do
      image_list = image_list(images)
      image_list.images.each do |image|
        stub_image(image.url, 'Not Found', 404)
      end

      expect { download.new(default_options_t).call(image_list) }
        .to raise_exception(Flickrage::DownloadError)

      image_list.images.each do |image|
        expect(File.exist?(image.local_path)).to be_falsey
        expect(a_request(:get, image.url))
          .to have_been_made
      end
    end
  end

  describe 'with no width, height' do
    before do
      Flickrage.configure do |config|
        config.output = nil
      end
    end

    it 'when nothing raise' do
      image_list = image_list(images)
      image_list.images.each do |image|
        stub_image(image.url, file)
      end

      expect { download.new(default_options_t).call(image_list) }
        .to raise_exception(Flickrage::PathError)

      image_list.images.each do |image|
        expect(File.exist?(image.local_path)).to be_falsey
        expect(a_request(:get, image.url))
          .not_to have_been_made
      end
    end
  end
end
