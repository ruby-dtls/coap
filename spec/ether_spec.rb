require 'spec_helper'

describe CoRE::CoAP::Ether do
  describe '#initialize' do
    describe 'without arguments' do
      it 'should set socket correctly' do
        ether = CoRE::CoAP::Ether.new
        expect(ether.socket.class).to eq(Celluloid::IO::UDPSocket)
        expect(ether.socket.class).not_to eq(::UDPSocket)
        expect(ether.address_family).to eq(Socket::AF_INET6)
      end
    end

    describe 'with ordinary UDPSocket' do
      it 'should set socket correctly' do
        ether = CoRE::CoAP::Ether.new(socket_class: ::UDPSocket)
        expect(ether.socket.class).to eq(::UDPSocket)
        expect(ether.socket.class).not_to eq(Celluloid::IO::UDPSocket)
        expect(ether.address_family).to eq(Socket::AF_INET6)
      end
    end
  end

  describe '#from_host' do
    it 'should set address family correctly for ipv6' do
      ether = CoRE::CoAP::Ether.from_host('::1')
      expect(ether.address_family).to eq(Socket::AF_INET6)
      expect(ether.address_family).not_to eq(Socket::AF_INET)
    end

    it 'should set address family correctly for ipv4' do
      ether = CoRE::CoAP::Ether.from_host('127.0.0.1')
      expect(ether.address_family).to eq(Socket::AF_INET)
      expect(ether.address_family).not_to eq(Socket::AF_INET6)
    end
  end

  describe '.send' do
    it 'should resolve' do
      expect { CoRE::CoAP::Ether.send('hello', '127.0.0.1') }.not_to raise_error
      expect { CoRE::CoAP::Ether.send('hello', '::1') }.not_to raise_error
      expect { CoRE::CoAP::Ether.send('hello', 'ipv4.orgizm.net') }.not_to raise_error
    end
  end
end
