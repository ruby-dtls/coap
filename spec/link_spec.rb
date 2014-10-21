require 'spec_helper'

describe CoRE::Link do
  describe '#initialize' do
    context 'with valid parameters' do
      context 'without attributes' do
        subject { CoRE::Link.new('test') }

        it 'should instantialize' do
          expect { subject }.not_to raise_error
          expect(subject.uri).to eq('test')
        end
      end
      
      context 'with attributes' do
        subject { CoRE::Link.new('test', if: 'test') }

        it 'should instantialize' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with invalid parameters' do
      subject { CoRE::Link.new('test', foo: 'bar') }

      it 'should raise error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'modification' do
    subject { CoRE::Link.new('test') }

    context 'with valid attributes' do
      it 'should work' do
        expect { subject.rel = 'hosts' }.not_to raise_error
        expect(subject.rel).to eq('hosts')
      end
    end

    context 'with invalid attributes' do
      it 'should fail' do
        expect { subject.foo }.to raise_error(ArgumentError)
        expect { subject.foo = 'bar' }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    subject { CoRE::Link.new('test', if: 'test', rel: 'hosts') }
    let(:text) { '<test>;if="test";rel="hosts"' }

    it 'should equal example' do
      expect(subject.to_s).to eq(text)
    end
  end

  describe '.parse' do
    let(:text) { '<test>;if="test";rel="hosts"' }
    subject { CoRE::Link.parse(text) }

    it 'should build object correctly' do
      expect(subject.to_s).to eq(text)
      expect(subject.if).to eq('test')
      expect(subject.rel).to eq('hosts')
      expect(subject.uri).to eq('test')
    end

    context 'with misformed input' do
      let(:text) { '<test>;if=""test;' }
      subject { CoRE::Link.parse(text) }

      it 'should work' do
        expect { subject }.not_to raise_error
      end
    end

    context 'of multiple links' do
      let(:text) { '<test>;if="test",<test>;if="test"' }
      subject { CoRE::Link.parse_multiple(text) }

      it 'should work' do
        expect(subject).to be_a(Array)
        expect(subject.size).to eq(2)
      end
    end

    context 'coap.me/.well-known/core' do
      subject { CoRE::Link.parse(fixture('coap.me.link')) }

      it 'should be parsed' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
