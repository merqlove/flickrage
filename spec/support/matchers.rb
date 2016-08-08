# frozen_string_literal: true
RSpec::Matchers.define(:be_same_file_as) do |expected_file_path|
  match do |actual_file_path|
    expect(md5_hash(actual_file_path)).to eq(md5_hash(expected_file_path))
  end

  def md5_hash(file_path)
    Digest::MD5.hexdigest(File.read(file_path))
  end
end

RSpec::Matchers.define(:be_same_file_as_lite) do |expected_file_path|
  match do |actual_file_path|
    expect(resolution(actual_file_path)).to eq(resolution(expected_file_path))
  end

  def resolution(file_path)
    img = MiniMagick::Image.open(file_path)
    [img.width,
     img.height,
     img.type,
     img.exif,
     img.dimensions,
     img.mime_type,
     img.colorspace,
     img.resolution,
     img.valid?].join('')
  end
end
