require 'spec_helper'

describe Resolver do
  context 'ipv6' do
    subject { IPAddr.new(Resolver.address('orgizm.net', true)) }

    it { expect { subject }.not_to raise_error }
    it { expect(subject.ipv6?).to be(true) }
  end

  context 'ipv4' do
    context 'from dns' do
      subject { IPAddr.new(Resolver.address('ipv4.orgizm.net')) }

      it { expect { subject }.not_to raise_error }
      it { expect(subject.ipv4?).to be(true) }
    end

    context 'default' do
      subject { IPAddr.new(Resolver.address('orgizm.net')) }

      it { expect { subject }.not_to raise_error }
      it { expect(subject.ipv4?).to be(true) }
    end
  end
end
