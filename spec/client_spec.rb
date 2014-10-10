# encoding: utf-8

require 'spec_helper'

describe CoRE::CoAP::Client do
  before do
    @client = CoRE::CoAP::Client.new
  end

  describe '#get' do
    describe 'with seperated answer' do
      it 'should return correct mcode and payload' do
        answer = @client.get('/separate', 'coap.me')
        expect(answer.mcode).to eq([2, 5])
        expect(answer.payload).to eq('That took a long time')
      end
    end
  end

  describe 'modifying methods' do
    before do
      @client       = CoRE::CoAP::Client.new(max_payload: 512)
      @payload      = Faker::Lorem.paragraphs(5).join("\n")
      @payload_utf8 = '♥' + @payload
    end

    describe '#post' do
      describe 'with block1 option' do
        describe 'creating resource' do
          it 'should work with ASCII payload' do
            answer = @client.post('/large-create', 'coap.me', nil, @payload)
            expect(answer.mcode).to eq([2, 1])

            answer = @client.get('/large-create', 'coap.me')
            expect(answer.mcode).to eq([2, 5])
            expect(answer.payload).to eq(@payload)
          end

          it 'should work with UTF8 payload' do
            answer = @client.post('/large-create', 'coap.me', nil, @payload_utf8)
            expect(answer.mcode).to eq([2, 1])

            answer = @client.get('/large-create', 'coap.me')
            expect(answer.mcode).to eq([2, 5])
            expect(answer.payload.force_encoding('utf-8')).to eq(@payload_utf8)
          end
        end
      end
    end

    describe '#put' do
      describe 'with block1 option' do
        describe 'updating resource' do
          it 'should work with ASCII payload' do
            answer = @client.put('/large-update', 'coap.me', nil, @payload)
            expect(answer.mcode).to eq([2, 4])

            answer = @client.get('/large-update', 'coap.me')
            expect(answer.mcode).to eq([2, 5])
            expect(answer.payload).to eq(@payload)
          end
        end
      end
    end
  end

  describe '#observe' do
    before do
      @answers = []

      @t1 = Thread.start do
        @client.observe \
          '/obs', 'vs0.inf.ethz.ch', nil,
          ->(m) { @answers << m }
      end

      Timeout.timeout(12) do
        sleep 0.25 while !(@answers.size > 2)
      end
    end

    it 'should receive updates' do
      expect(@answers.size).to be > 2
    end

    after do
      @t1.kill
    end
  end
end
