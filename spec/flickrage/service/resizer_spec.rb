# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Service::Resizer do
  include_context 'environment'

  subject(:resize) { described_class }

  before do
    remove_files('*.jpg')
    Flickrage.configure do |config|
      config.output = "#{project_path}/tmp"
    end
  end

  let(:image_file_name) { 'image.jpg' }
  let(:file) { file_path(image_file_name) }
  let(:resized_file) { file_path('resized.image.jpg') }
  let(:width) { 200 }
  let(:height) { 200 }

  let(:image_params) do
    { url: url_l, keyword: keyword, id: id, width: width_l, height: height_l,
      title: title, file_name: image_file_name, download: false }
  end

  let(:image)    { Flickrage::Entity::Image.new(image_params.merge(download: true)) }
  let(:no_image) { Flickrage::Entity::Image.new(image_params) }

  describe 'with success resize' do
    it 'when resized' do
      copy_image
      new_image = resize.new(width, height).run(image)

      expect(new_image.resized?).to be_truthy
      expect(File.exist?(new_image.local_path)).to be_truthy
      expect(File.exist?(new_image.resize_path)).to be_truthy
      expect(new_image.local_path).to be_same_file_as_lite(file)
      expect(new_image.resize_path).to be_same_file_as_lite(resized_file)
    end
  end

  describe 'with failed resize' do
    it 'when broken image' do
      copy_image
      new_image = resize.new(width, height).run(no_image)

      expect(new_image).not_to be_nil
      expect(new_image.resized?).to be_falsey
      expect(File.exist?(new_image.resize_path)).to be_falsey
    end

    it 'when loose' do
      new_image = resize.new(width, height).run(image)

      expect(new_image).not_to be_nil
      expect(new_image.resized?).to be_falsey
      expect(File.exist?(new_image.resize_path)).to be_falsey
    end
  end
end
