require_relative 'lib/core/coap/version'

Gem::Specification.new do |s|
  s.name = 'coap'

  s.summary = 'Pure Ruby implementation of RFC 7252 (Constrained Application Protocol (CoAP))'
  s.description = 'Pure Ruby implementation of RFC 7252 (Constrained Application
    Protocol (CoAP)). The Constrained Application Protocol (CoAP) is a
    specialized web transfer protocol for use with constrained nodes and
    constrained (e.g., low-power, lossy) networks. The nodes often have 8-bit
    microcontrollers with small amounts of ROM and RAM, while constrained
    networks such as IPv6 over Low-Power Wireless Personal Area Networks
    (6LoWPANs) often have high packet error rates and a typical throughput of
    10s of kbit/s. The protocol is designed for machine-to-machine (M2M)
    applications such as smart energy and building automation.'

  s.homepage = 'https://gitlab.informatik.uni-bremen.de/cabo/coap-message'
  s.version = CoRE::CoAP::VERSION
  s.licenses = 'MIT'
  s.authors = ['Carsten Bormann', 'henning mueller']
  s.email = 'henning@orgizm.net'
  s.files = Dir.glob('{bin,lib}/**/*')
# s.executables = Dir.glob('bin/**').map { |x| x[4..-1] }

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.1'
end
