# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Worker::Compose do
  include_context 'environment'

  subject(:compose) { described_class }

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

  let(:file_name) { 'collage.image.jpg' }

  let(:resized_file) { file_path('resized.image.jpg') }
  let(:collage_file) { file_path('collage.image.10.jpg') }
  let(:width) { 200 }
  let(:height) { 200 }

  def url(image)
    "http://some.host.com/#{image}"
  end

  def image(file_name, resize = true)
    Flickrage::Entity::Image.new(url: url(file_name), keyword: keyword, id: id, width: width_l,
                                 height: height_l, title: title, file_name: file_name, download: true,
                                 resize: resize)
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

  describe 'with success compose' do
    it 'when collage success' do
      image_list = image_list(images)
      image_list.images.each do |image|
        copy_image('resized.image.jpg', "resized.#{image.file_name}")
      end

      new_image_list = compose.new(default_options_t.merge(file_name: file_name)).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.composed?).to be_truthy
      expect(File.exist?(new_image_list.collage_path)).to be_truthy
      expect(new_image_list.collage_path).to be_same_file_as_lite(collage_file)
    end

    it 'when resized few images' do
      bad_images  = no_images[0..4]
      good_images = images[5..9]
      image_list = image_list(bad_images + good_images)
      image_list.images.each do |image|
        copy_image('resized.image.jpg', "resized.#{image.file_name}")
      end

      new_image_list = compose.new(default_options_t.merge('file_name' => file_name)).call(image_list)

      expect(new_image_list).not_to be_nil
      expect(new_image_list.composed?).to be_truthy
      expect(File.exist?(new_image_list.collage_path)).to be_truthy
      expect(new_image_list.collage_path).not_to be_same_file_as_lite(collage_file)
    end
  end

  describe 'with fail on something' do
    it 'when nothing resized raise' do
      image_list = image_list(no_images)
      image_list.collage_path = file_name
      image_list.images.each do |image|
        copy_image('resized.image.jpg', "resized.#{image.file_name}")
      end

      expect { compose.new(default_options_t.merge('file_name' => file_name)).call(image_list) }
        .to raise_exception(Flickrage::CollageError)

      expect(File.exist?(image_list.collage_path)).to be_falsey
    end

    it 'when files not found raise' do
      image_list = image_list(images)
      image_list.collage_path = file_name

      expect { compose.new(default_options_t.merge('file_name' => file_name)).call(image_list) }
        .to raise_exception(Flickrage::CollageError)

      expect(File.exist?(image_list.collage_path)).to be_falsey
    end

    it 'when no file_name raise' do
      image_list = image_list(images)
      image_list.collage_path = file_name
      image_list.images.each do |image|
        copy_image('resized.image.jpg', "resized.#{image.file_name}")
      end

      expect { compose.new(default_options_t.merge('file_name' => nil)).call(image_list) }
        .to raise_exception(Flickrage::FileNameError)

      expect(File.exist?(image_list.collage_path)).to be_falsey
    end
  end
end
