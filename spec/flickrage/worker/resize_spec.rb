# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Worker::Resize do
  include_context 'environment'

  subject(:resize) { described_class }

  before do
    remove_files('*.jpg')
    Flickrage.configure do |config|
      config.output = "#{project_path}/tmp"
      config.max = 10
      config.verbose = false
      config.width = width
      config.height = height
    end
  end

  let(:file) { file_path('image.jpg') }
  let(:resized_file) { file_path('resized.image.jpg') }
  let(:width) { 200 }
  let(:height) { 200 }

  def url(image)
    "http://some.host.com/#{image}"
  end

  def image(file_name, download = true)
    Flickrage::Entity::Image.new(url: url(file_name), keyword: keyword, id: id, width: width_l,
                                 height: height_l, title: title, file_name: file_name, download: download)
  end

  def image_list(images)
    Flickrage::Entity::ImageList.new(images: images, total: images.size)
  end

  let(:images) do
    (1..9).map { |i| image("image#{i}.jpg") } + [image('image.jpg')]
  end

  let(:no_images) do
    (1..9).map { |i| image("image#{i}.jpg", false) } + [image('image.jpg', false)]
  end

  describe 'with success' do
    it 'when resized all images' do
      image_list = image_list(images)
      image_list.images.each do |image|
        copy_image('image.jpg', image.file_name)
      end

      new_image_list = resize.new(default_options_t).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.size).to eq(10)
      expect(new_image_list.valid?).to be_truthy

      new_image_list.images.each do |image|
        expect(image.resized?).to be_truthy
        expect(File.exist?(image.local_path)).to be_truthy
        expect(File.exist?(image.resize_path)).to be_truthy
        expect(image.local_path).to be_same_file_as_lite(file)
        expect(image.resize_path).to be_same_file_as_lite(resized_file)
      end

      expect(new_image_list.images.count(&:resized?)).to eq(10)
    end

    it 'when resized few images' do
      bad_images  = no_images[0..4]
      good_images = images[5..9]
      image_list = image_list(bad_images + good_images)
      image_list.images.each do |image|
        copy_image('image.jpg', image.file_name)
      end

      new_image_list = resize.new(default_options_t).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.size).to eq(10)
      expect(new_image_list.valid?).to be_truthy

      new_image_list.images.each do |image|
        if image.downloaded?
          expect(image.resized?).to be_truthy
          expect(File.exist?(image.resize_path)).to be_truthy
          expect(image.resize_path).to be_same_file_as_lite(resized_file)
        else
          expect(image.resized?).to be_falsey
          expect(File.exist?(image.resize_path)).to be_falsey
        end
        expect(image.local_path).to be_same_file_as_lite(file)
        expect(File.exist?(image.local_path)).to be_truthy
      end

      expect(new_image_list.images.count(&:resized?)).to eq(5)
    end

    it 'when no files on disk' do
      bad_images  = no_images[0..4]
      good_images = images[5..9]
      image_list = image_list(bad_images + good_images)

      good_images.each do |image|
        copy_image('image.jpg', image.file_name)
      end

      new_image_list = resize.new(default_options_t).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.size).to eq(10)
      expect(new_image_list.valid?).to be_truthy

      new_image_list.images.each do |image|
        if image.downloaded?
          expect(image.resized?).to be_truthy
          expect(File.exist?(image.local_path)).to be_truthy
          expect(image.local_path).to be_same_file_as_lite(file)
          expect(File.exist?(image.resize_path)).to be_truthy
          expect(image.resize_path).to be_same_file_as_lite(resized_file)
        else
          expect(image.resized?).to be_falsey
          expect(File.exist?(image.local_path)).to be_falsey
          expect(File.exist?(image.resize_path)).to be_falsey
        end
      end

      expect(new_image_list.images.count(&:resized?)).to eq(5)
    end
  end

  describe 'with fail' do
    it 'when nothing downloaded raise' do
      image_list = image_list(no_images)
      image_list.images.each do |image|
        copy_image('image.jpg', image.file_name)
      end

      expect { resize.new(default_options_t).call(image_list) }
        .to raise_exception(Flickrage::ResizeError)

      image_list.images.each do |image|
        expect(File.exist?(image.resize_path)).to be_falsey
      end
    end

    it 'when nothing resized raise' do
      image_list = image_list(images)

      expect { resize.new(default_options_t).call(image_list) }
        .to raise_exception(Flickrage::ResizeError)

      image_list.images.each do |image|
        expect(File.exist?(image.resize_path)).to be_falsey
      end
    end
  end

  describe 'with no width, height' do
    before do
      Flickrage.configure do |config|
        config.width = nil
        config.height = nil
      end
    end

    it 'when nothing raise' do
      image_list = image_list(images)
      image_list.images.each do |image|
        copy_image('image.jpg', image.file_name)
      end

      expect { resize.new(default_options_t).call(image_list) }
        .to raise_exception(Flickrage::NumberError)

      image_list.images.each do |image|
        expect(File.exist?(image.resize_path)).to be_falsey
      end
    end
  end
end
