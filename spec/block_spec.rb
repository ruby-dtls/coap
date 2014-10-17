require 'spec_helper'
require 'benchmark'

describe Block do
  before do
    @block = Block.new(0, false, 16)
    @data1 = '+' * 42
    @data2 = '+' * 32
  end

  describe '#chunk' do
    it 'should return chunks' do
      a = [0, 1, 2, 3].map do |i|
        @block.num = i
        @block.chunk(@data1)
      end

      expect(a).to eq(['+' * 16, '+' * 16, '+' * 10, nil])
    end
  end

  describe '#chunk_count' do
    it 'should return correct count' do
      expect(@block.chunk_count(@data1)).to eq(3)
      expect(@block.chunk_count(@data2)).to eq(2)
    end
  end

  describe '#last?' do
    it 'should return false unless last chunk' do
      [0, 1, 3].each do |num|
        @block.num = num
        expect(@block.last?(@data1)).to be false
      end

      [0, 2, 3].each do |num|
        @block.num = num
        expect(@block.last?(@data2)).to be false
      end
    end

    it 'should return true if last chunk' do
      @block.num = 2
      expect(@block.last?(@data1)).to be true

      @block.num = 1
      expect(@block.last?(@data2)).to be true
    end
  end

  describe '#encode' do
    it 'should work with examples' do
      expect(@block.encode).to eq(0)

      block = Block.new(0, true, 16)
      expect(block.encode).to eq(8)

      (1..6).each do |i|
        block = Block.new(0, false, 2**(i+4))
        expect(block.encode).to eq(i)
      end
    end
  end

  describe '#encode and #decode' do
    it 'should be reversible (encode -> decode)' do
      num = rand(Block::MAX_NUM + 1)
      more = [true, false].sample
      size = Block::VALID_SIZE.sample

      a = Block.new(num, more, size).encode
      b = Block.new(a).decode

      expect(b.num).to  eq(num)
      expect(b.more).to eq(more)
      expect(b.size).to eq(size)
    end

    it 'should be reversible (decode -> encode)' do
      i = 7
      i = rand(2**24) until (i & 7) != 7

      a = Block.new(i).decode
      b = Block.new(a.num, a.more, a.size).encode

      expect(b).to eq(i)
    end
  end
end
