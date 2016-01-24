require 'spec_helper'

describe Transmission do
  describe '#initialize' do
    context 'without arguments' do
      subject { Transmission.new }

      it 'should set socket correctly' do
        expect(subject.socket.class).to eq(Celluloid::IO::UDPSocket)
        expect(subject.socket.class).not_to eq(::UDPSocket)
        expect(subject.address_family).to eq(Socket::AF_INET6)
      end
    end

    context 'with ordinary UDPSocket' do
      subject { Transmission.new(socket_class: ::UDPSocket) }

      it 'should set socket correctly' do
        expect(subject.socket.class).to eq(::UDPSocket)
        expect(subject.socket.class).not_to eq(Celluloid::IO::UDPSocket)
        expect(subject.address_family).to eq(Socket::AF_INET6)
      end
    end
  end

  describe '#from_host' do
    context 'ipv6' do
      subject { Transmission.from_host('::1') }

      it 'should set address family correctly' do
        expect(subject.address_family).to eq(Socket::AF_INET6)
        expect(subject.address_family).not_to eq(Socket::AF_INET)
      end
    end

    context 'ipv4' do
      subject { Transmission.from_host('127.0.0.1') }

      it 'should set address family correctly' do
        expect(subject.address_family).to eq(Socket::AF_INET)
        expect(subject.address_family).not_to eq(Socket::AF_INET6)
      end
    end
  end

  describe '.send' do
    context 'resolve' do
      it 'no error for IP addresses' do
        expect { Transmission.send('hello', '127.0.0.1') }.not_to raise_error

        if ENV['NO_IPV6_TESTS'].nil?
          expect { Transmission.send('hello', '::1') }.not_to raise_error
        end
      end

      it 'error for invalid host' do
        expect { Transmission.send('hello', '.') }.to raise_error(Resolv::ResolvError)
      end

      context 'hostnames' do
        it 'ipv4' do
          expect(Transmission.from_host('ipv4.orgizm.net').ipv6?).to be(false)
        end

        it 'ipv6' do
          expect(Transmission.from_host('orgizm.net', force_ipv6: true).ipv6?).to be(true)
        end
      end
    end
  end
end
