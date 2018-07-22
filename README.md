[![Gem Version](https://img.shields.io/gem/v/coap.svg)](http://badge.fury.io/rb/coap)
[![Build Status](https://img.shields.io/travis/nning/coap.svg)](https://travis-ci.org/nning/coap)
[![Coverage Status](https://img.shields.io/coveralls/nning/coap.svg)](https://coveralls.io/r/nning/coap)
[![Code Climate](https://codeclimate.com/github/nning/coap/badges/gpa.svg)](https://codeclimate.com/github/nning/coap)

# CoAP

This Ruby gem implements client functionality for [RFC
7252](http://tools.ietf.org/html/rfc7252), the Constrained Application Protocol
(CoAP). The message parsing code included is written by Carsten Bormann, one of
the RFC authors.

The Constrained Application Protocol (CoAP) is a specialized web transfer
protocol for use with constrained nodes and constrained (e.g., low-power,
lossy) networks.  The nodes often have 8-bit microcontrollers with small
amounts of ROM and RAM, while constrained networks such as 6LoWPAN often have
high packet error rates and a typical throughput of 10s of kbit/s.  The
protocol is designed for machine-to-machine (M2M) applications such as smart
energy and building automation.

Additionally supported extensions of the CoAP protocol:

* [Blockwise Transfer](http://tools.ietf.org/html/draft-ietf-core-block-14)
* [Observe](http://tools.ietf.org/html/draft-ietf-core-observe-13)

## Install

Add this line to your application's Gemfile:

    gem 'coap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coap

## Usage

### In your Application

	require 'coap'

    CoAP::Client.new.get_by_uri('coap://coap.me/hello').payload
	=> "world"

	CoAP::Client.new.get('/hello', 'coap.me')
	=> #<struct CoRE::CoAP::Message ver=1, tt=:ack, mcode=[2, 5], mid=51490, options={:max_age=>60, :token=>366862489, :content_format=>0}, payload="world">

	c = CoAP::Client.new(host: 'coap.me')
	c.get('/hello')

See [the API documentation at
rubydoc.info](http://www.rubydoc.info/github/nning/coap/master/CoRE/CoAP/Client)
or `test/test_client.rb` for more examples.

### On the Command Line

The command line client supports the basic CoAP methods.

    coap get coap://coap.me/.well-known/core

## Testing

    rake

## Copyright

The code is published under the MIT license (see the LICENSE file).

### Authors

* Carsten Bormann
* Simon Frerichs
* [henning mueller](https://nning.io)
