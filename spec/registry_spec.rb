require 'spec_helper'

describe Registry do
  it 'should have already loaded content formats YAML' do
    [
      Registry::CONTENT_FORMATS,
      Registry::CONTENT_FORMATS_INVERTED
    ].each do |o|
      expect(o).to be_a(Hash)
      expect(o.empty?).to be(false)
      expect(o.frozen?).to be(true)
    end
  end

  it 'should convert integer' do
    Registry::CONTENT_FORMATS.each do |k, v|
      expect(Registry.convert_content_format(k)).to eq(v)
    end
  end

  it 'should convert string' do
    Registry::CONTENT_FORMATS.each do |k, v|
      expect(Registry.convert_content_format(v)).to eq(k)
    end
  end
end
