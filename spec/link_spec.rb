require 'spec_helper'

describe CoRE::Link do
  describe 'creation' do
    describe 'with valid parameters' do
      it 'without attributes' do
        expect { CoRE::Link.new('test') }.not_to raise_error

        expect(CoRE::Link.new('test').uri).to eq('test')
      end
      
      it 'and attributes' do
        expect { CoRE::Link.new('test', if: 'test') }.not_to raise_error
      end
    end

    it 'with invalid attribute should raise' do
      expect { CoRE::Link.new('test', foo: 'bar') }.to raise_error(ArgumentError)
    end
  end

  describe 'modification' do
    before do
      @link = CoRE::Link.new('test')
    end

    it 'with valid attributes' do
      expect { @link.rel = 'hosts' }.not_to raise_error

      expect(@link.rel).to eq('hosts')
    end

    it 'with invalid attributes' do
      expect { @link.foo }.to raise_error(ArgumentError)
      expect { @link.foo = 'bar' }.to raise_error(ArgumentError)
    end
  end

  describe '#to_s' do
    it 'should equal example' do
      text = '<test>;if="test";rel="hosts"'
      link = CoRE::Link.new('test', if: 'test', rel: 'hosts')

      expect(link.to_s).to eq(text)
    end
  end

  describe 'parsing' do
    it 'should build object correctly' do
      text = '<test>;if="test";rel="hosts"'
      link = CoRE::Link.parse(text)

      expect(link.to_s).to eq(text)
      expect(link.if).to eq('test')
      expect(link.rel).to eq('hosts')
      expect(link.uri).to eq('test')
    end

    it 'should not fail on misformed input' do
      text = '<test>;if=""test;'
      expect { CoRE::Link.parse(text) }.not_to raise_error
    end

    describe 'of multiple links' do
      it 'should not fail' do
        text = '<test>;if="test",<test>;if="test"'
        links = CoRE::Link.parse_multiple(text)

        expect(links).to be_a(Array)
        expect(links.size).to eq(2)
      end
    end
  end
end
