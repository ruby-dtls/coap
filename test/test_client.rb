# encoding: utf-8

require 'helper'

# TODO Rewrite tests with local coap server!

class TestClient < Minitest::Test
  def test_client_get_v4_v6_hostname
    client = CoRE::CoAP::Client.new
    answer = client.get('/hello', 'coap.me')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    coap_me_ipv4_address = Addrinfo.ip('4.coap.me').ip_address

    client = CoRE::CoAP::Client.new
    answer = client.get('/hello', coap_me_ipv4_address)
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    if ENV['NO_IPV6_TESTS'].nil?
      coap_me_ipv6_address = Addrinfo.ip('6.coap.me').ip_address

      client = CoRE::CoAP::Client.new
      answer = client.get('/hello', coap_me_ipv6_address)
      assert_equal([2, 5], answer.mcode)
      assert_equal('world', answer.payload)
    end
  end

  def test_client_404
    client = CoRE::CoAP::Client.new
    answer = client.get('/hello-this-does-not-exist', 'coap.me')

    assert_equal([4, 4], answer.mcode)
    assert_equal('Not found', answer.payload)
  end

  def test_invalid_hostname
    assert_raises Resolv::ResolvError do
      CoRE::CoAP::Client.new.get('/', 'unknown.tld')
    end
  end

  def test_recv_timeout
    client = CoRE::CoAP::Client.new(max_retransmit: 0, recv_timeout: 0.1)

    assert_raises RuntimeError do
      client.get('/hello', '192.0.2.1')
    end
  end

  def test_recv_timeout_retransmit
    client = CoRE::CoAP::Client.new(max_retransmit: 1, recv_timeout: 1)

    assert_raises RuntimeError do
      client.get('/hello', 'eternium.orgizm.net', 1195)
    end
  end

  def test_client_arguments
    client = CoRE::CoAP::Client.new

    # Wrong port
    assert_raises RuntimeError do
      client.get('/hello', 'coap.me', 15_683)
    end

    # Empty path
    assert_raises ArgumentError do
      answer = client.get('', 'coap.me')
    end

    # Empty host
    assert_raises ArgumentError do
      answer = client.get('/', '')
    end

    # String port
    assert_raises ArgumentError do
      answer = client.get('/', '192.0.2.1', 'string')
    end

    # Empty payload
    assert_raises ArgumentError do
      answer = client.post('/large-create', 'coap.me', nil, '')
    end
  end

  def test_client_get_by_uri
    client = CoRE::CoAP::Client.new

    answer = client.get_by_uri('coap://coap.me/hello')
    assert_equal('world', answer.payload)

    answer = client.get_by_uri('coap://coap.me:5683/hello')
    assert_equal('world', answer.payload)

    # Broken URI
    assert_raises ArgumentError do
      answer = client.get_by_uri('coap:/#/coap.me/hello')
    end
  end

  # TODO test payload

  # Basic POST test
  def test_client_post
    client = CoRE::CoAP::Client.new
    answer = client.post('/test', 'coap.me', nil, 'TD_COAP_CORE_04')

    assert_equal([2, 1], answer.mcode)
    assert_equal('POST OK', answer.payload)
  end

  # Basic PUT test
  def test_client_put
    client = CoRE::CoAP::Client.new
    answer = client.put('/test', 'coap.me', nil, 'TD_COAP_CORE_03')

    assert_equal([2, 4], answer.mcode)
    assert_equal('PUT OK', answer.payload)
  end

  def test_client_delete
    client = CoRE::CoAP::Client.new
    answer = client.delete('/test', 'coap.me')

    assert_equal([2, 2], answer.mcode)
    assert_equal('DELETE OK', answer.payload)
  end

  def test_client_sönderzeichen
    client = CoRE::CoAP::Client.new
    answer = client.get_by_uri('coap://coap.me/bl%C3%A5b%C3%A6rsyltet%C3%B8y')

    assert_equal([2, 5], answer.mcode)
    assert_equal('Übergrößenträger = 特大の人 = 超大航母', answer.payload.force_encoding('utf-8'))
  end

  def test_multi_request_without_hostname_port
    client = CoRE::CoAP::Client.new
    client.host = 'coap.me'
    client.port = 5683

    # Are host and port set?
    answer = client.get('/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    # Do they keep to be set after a request?
    answer = client.get('/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    client = CoRE::CoAP::Client.new

    # Ordinary request.
    answer = client.get('/hello', 'coap.me')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    # Did previous request set host?
    answer = client.get('/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    # Is it kept?
    answer = client.get('/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)
  end

  def test_initialize
    client = CoRE::CoAP::Client.new(host: 'coap.me', max_payload: 16)
    answer = client.get('/large')
    assert_equal([2, 5], answer.mcode)
    assert_equal(%Q'\n     0                   1                   2                   3\n    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |Ver| T |  TKL  |      Code     |          Message ID           |\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Token (if any, TKL bytes) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Options (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |1 1 1 1 1 1 1 1|    Payload (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n\n[...]\n\n   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of\n      the variable-length Token field (0-8 bytes).  Lengths 9-15 are\n      reserved, MUST NOT be sent, and MUST be processed as a message\n      format error.\n\n   Code:  8-bit unsigned integer, split into a 3-bit class (most\n      significant bits) and a 5-bit detail (least significant bits),\n      documented as c.dd where c is a digit from 0 to 7 for the 3-bit\n      subfield and dd are two digits from 00 to 31 for the 5-bit\n      subfield.  The class can indicate a request (0), a success\n      response (2), a client error response (4), or a server error\n      response (5).  (All other class values are reserved.)  As a\n      special case, Code 0.00 indicates an Empty message.  In case of a\n      request, the Code field indicates the Request Method; in case of a\n      response a Response Code.  Possible values are maintained in the\n      CoAP Code Registries (Section 12.1).  The semantics of requests\n      and responses are defined in Section 5.\n\n', answer.payload)
  end

  def test_client_block2
    client = CoRE::CoAP::Client.new
    client.max_payload = 512
    answer = client.get('/large', 'coap.me')
    assert_equal([2, 5], answer.mcode)
    assert_equal(%Q'\n     0                   1                   2                   3\n    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |Ver| T |  TKL  |      Code     |          Message ID           |\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Token (if any, TKL bytes) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Options (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |1 1 1 1 1 1 1 1|    Payload (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n\n[...]\n\n   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of\n      the variable-length Token field (0-8 bytes).  Lengths 9-15 are\n      reserved, MUST NOT be sent, and MUST be processed as a message\n      format error.\n\n   Code:  8-bit unsigned integer, split into a 3-bit class (most\n      significant bits) and a 5-bit detail (least significant bits),\n      documented as c.dd where c is a digit from 0 to 7 for the 3-bit\n      subfield and dd are two digits from 00 to 31 for the 5-bit\n      subfield.  The class can indicate a request (0), a success\n      response (2), a client error response (4), or a server error\n      response (5).  (All other class values are reserved.)  As a\n      special case, Code 0.00 indicates an Empty message.  In case of a\n      request, the Code field indicates the Request Method; in case of a\n      response a Response Code.  Possible values are maintained in the\n      CoAP Code Registries (Section 12.1).  The semantics of requests\n      and responses are defined in Section 5.\n\n', answer.payload)
  end
end
