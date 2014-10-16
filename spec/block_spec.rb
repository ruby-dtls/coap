require 'spec_helper'
require 'benchmark'

describe CoRE::CoAP::Block do
  before do
    @block = CoRE::CoAP::Block.new(0, false, 16)
    @data  = '+' * 42
  end

  describe '#chunk' do
    it 'should return chunks' do
      a = [0, 1, 2, 3].map do |i|
        @block.num = i
        @block.chunk(@data)
      end

      expect(a).to eq(['+' * 16, '+' * 16, '+' * 10, nil])
    end
  end

  describe '#last?' do
    [42, 32].each do |size|
      @data = '+' * size

      it 'should return false unless last chunk' do
        [0, 1, 3, 4, 5].each do |num|
          @block.num = num
          expect(@block.last?(@data)).to be false
        end
      end

      it 'should return true if last chunk' do
        @block.num = 2
        expect(@block.last?(@data)).to be true
      end
    end
  end

  describe '#encode' do
    it 'should work with examples' do
      expect(@block.encode).to eq(0)

      block = CoRE::CoAP::Block.new(0, true, 16)
      expect(block.encode).to eq(8)

      (1..6).each do |i|
        block = CoRE::CoAP::Block.new(0, false, 2**(i+4))
        expect(block.encode).to eq(i)
      end
    end
  end

  describe '#encode and #decode' do
    it 'should be reversible (encode -> decode)' do
      num = rand(CoRE::CoAP::Block::MAX_NUM + 1)
      more = [true, false].sample
      size = CoRE::CoAP::Block::VALID_SIZE.sample

      a = CoRE::CoAP::Block.new(num, more, size).encode
      b = CoRE::CoAP::Block.new(a).decode

      expect(b.num).to  eq(num)
      expect(b.more).to eq(more)
      expect(b.size).to eq(size)
    end

    it 'should be reversible (decode -> encode)' do
      i = 7
      i = rand(2**24) until (i & 7) != 7

      a = CoRE::CoAP::Block.new(i).decode
      b = CoRE::CoAP::Block.new(a.num, a.more, a.size).encode

      expect(b).to eq(i)
    end
  end

  describe '.log2' do
    it 'should equal Math.log2 for a VALID_SIZE' do
      CoRE::CoAP::Block::VALID_SIZE.each do |size|
        expect(CoRE::CoAP::Block.log2(size)).to eq(Math.log2(size))
      end
    end

    it 'should be faster than Math.log2' do
      i = rand(2**15)

      a = Benchmark.realtime { CoRE::CoAP::Block.log2(i) }
      b = Benchmark.realtime { Math.log2(i).floor }

      expect(a).to be < b
    end
  end
end
