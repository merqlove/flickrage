# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Service::Composer do
  include_context 'environment'

  subject(:compose) { described_class }

  before do
    remove_files('*.jpg')
    Flickrage.configure do |config|
      config.output = "#{project_path}/tmp"
    end
  end

  let(:image_file_name)  { 'image.jpg' }
  let(:image_file_name2) { 'image2.jpg' }

  let(:resized_file_name)  { "resized.#{image_file_name}" }
  let(:resized_file_name2) { "resized.#{image_file_name2}" }

  let(:file_name) { 'collage.image.jpg' }

  let(:resized_file) { file_path('resized.image.jpg') }
  let(:collage_file) { file_path('collage.image.jpg') }
  let(:width) { 200 }
  let(:height) { 200 }

  describe 'with success compose' do
    it 'when composed' do
      copy_image(resized_file_name, resized_file_name)
      copy_image(resized_file_name2, resized_file_name2)
      list = image_list(image(image_file_name), image(image_file_name2))
      list.collage_path = file_name
      new_list = compose.new(file_name, width, height, shuffle: false).run(list)
      expect(new_list.composed?).to be_truthy
      expect(File.exist?(new_list.collage_path)).to be_truthy
      expect(new_list.collage_path).to be_same_file_as_lite(collage_file)
    end
  end

  describe 'with failed compose' do
    it 'when loose' do
      list = image_list
      list.collage_path = file_name
      new_list = compose.new(file_name, width, height, shuffle: false).run(list)
      expect(new_list).not_to be_nil
      expect(new_list.composed?).to be_falsey
      expect(File.exist?(new_list.collage_path)).to be_falsey
    end
  end

  def image_list(*images)
    Flickrage::Entity::ImageList.new(images: images, total: images.size)
  end

  def image(file_name = image_file_name)
    Flickrage::Entity::Image.new(url: url_l, keyword: keyword, id: id, width: width_l, height: height_l,
                                 title: title, file_name: file_name, resize: true, download: true)
  end
end
