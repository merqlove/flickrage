# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Flickrage::Entity::Image do
  include_context 'environment'

  subject(:image) { described_class }

  let(:success_params) do
    { id: 5, title: 'some', keyword: 'keyword', url: 'https://yandex.ru/some.jpg',
      file_name: 'some.jpg', width: 700, height: 500, download: true, resize: false }
  end

  let(:wrong_params) do
    { id: [], title: {}, keyword: 55 }
  end

  describe '#new' do
    it 'with success params' do
      img = image.new(success_params)
      expect(img.id).to eq success_params[:id]
      expect(img.keyword).to eq success_params[:keyword]
      expect(img.url).to eq success_params[:url]
      expect(img.file_name).to eq success_params[:file_name]
      expect(img.width).to eq success_params[:width]
      expect(img.height).to eq success_params[:height]
      expect(img.download).to eq success_params[:download]
      expect(img.resize).to eq success_params[:resize]
    end

    it 'with default params' do
      img = image.new({})
      expect(img.download).to eq(false)
      expect(img.resize).to eq(false)
    end

    it 'with wrong params' do
      expect { image.new(wrong_params) }
        .to raise_exception(TypeError)
    end
  end

  describe '#downloaded?' do
    it 'success' do
      img = image.new(success_params)
      expect(img.downloaded?).to eq(success_params[:download])
    end
  end

  describe '#resized?' do
    it 'success' do
      img = image.new(success_params)
      expect(img.resized?).to eq(success_params[:resize])
    end
  end
end
