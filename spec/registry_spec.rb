require 'spec_helper'

describe Registry do
  context '.load_yaml' do
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
  end

  describe '.convert_content_format' do
    context 'Integer' do
      it 'should convert' do
        Registry::CONTENT_FORMATS.each do |k, v|
          expect(Registry.convert_content_format(k)).to eq(v)
        end
      end
    end

    context 'String' do
      it 'should convert' do
        Registry::CONTENT_FORMATS.each do |k, v|
          expect(Registry.convert_content_format(v)).to eq(k)
        end
      end

      it 'should convert without charset' do
        expect(Registry.convert_content_format('text/plain')).to eq(0)
      end
    end
  end
end
