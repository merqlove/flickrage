# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Entity::ImageList do
  include_context 'environment'

  subject(:image_list) { described_class }

  let(:image) do
    Flickrage::Entity::Image.new(id: 5, title: 'some', keyword: 'keyword', url: 'https://yandex.ru/some.jpg',
                                 file_name: 'some.jpg', width: 700, height: 500, download: true, resize: true)
  end

  let(:success_params) do
    { images: [image, image, image, image, image], not_founds: %w(aaa bbb), total: 5, compose: true,
      collage_path: './tmp/collage.some.jpg' }
  end

  let(:wrong_params) do
    { compose: [], collage_path: {} }
  end

  describe '#new' do
    it 'with success params' do
      list = image_list.new(success_params)
      expect(list.images).to eq success_params[:images]
      expect(list.not_founds).to eq success_params[:not_founds]
      expect(list.total).to eq success_params[:total]
      expect(list.compose).to eq success_params[:compose]
      expect(list.collage_path).to eq success_params[:collage_path]
    end

    it 'with default params' do
      list = image_list.new({})
      expect(list.images).to eq([])
      expect(list.not_founds).to eq([])
      expect(list.total).to eq(0)
      expect(list.compose).to eq(false)
    end

    it 'with wrong params' do
      expect { image_list.new(wrong_params) }
        .to raise_exception(TypeError)
    end
  end

  describe '#composed?' do
    it 'success' do
      list = image_list.new(success_params)
      expect(list.composed?).to eq(success_params[:compose])
    end
  end

  describe '#downloaded' do
    it 'success' do
      list = image_list.new(success_params)
      expect(list.downloaded.count).to eq(success_params[:images].count(&:downloaded?))
    end
  end

  describe '#resized' do
    it 'success' do
      list = image_list.new(success_params)
      expect(list.resized.count).to eq(success_params[:images].count(&:resized?))
    end
  end
end
