# encoding: utf-8

require_relative 'helper'

# TODO Rewrite tests with local coap server!

PAYLOAD = Faker::Lorem.paragraphs(5).join("\n")
PAYLOAD_UTF8 = '♥' + PAYLOAD

class TestClient < Minitest::Test
  @@observe_count = 0

  def observe_tester(data, socket)
    @@observe_count += 1
  end

  def test_client_get_v4_v6_hostname
    # client = CoRE::CoAP::Client.new
    # answer = client.get('2001:638:708:30da:219:d1ff:fea4:abc5', 5683, '/hello')
    # assert_equal([2, 5],answer.mcode)
    # assert_equal('world',answer.payload)

    client = CoRE::CoAP::Client.new
    answer = client.get('coap.me', 5683, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    client = CoRE::CoAP::Client.new
    answer = client.get('134.102.218.16', 5683, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)
  end

  def test_client_404
    client = CoRE::CoAP::Client.new
    answer = client.get('coap.me', 5683, '/hello-this-does-not-exist')

    assert_equal([4, 4], answer.mcode)
    assert_equal('Not found', answer.payload)
  end

  def test_host_down
    client = CoRE::CoAP::Client.new
    assert_raises RuntimeError do
      answer = client.get('192.0.2.1', 5683, '/hello')
    end
  end

  def test_invalid_hostname
    client = CoRE::CoAP::Client.new
    assert_raises Resolv::ResolvError do
      client.get('unknown.tld', 5683, '/hello')
    end
  end

  def test_ack_timeout
    client = CoRE::CoAP::Client.new(max_retransmit: 0, ack_timeout: 0.1)

    assert_raises RuntimeError do
      client.get('eternium.orgizm.net', 1195, '/hello')
    end
  end

  def test_ack_timeout_retransmit
    client = CoRE::CoAP::Client.new(max_retransmit: 1, ack_timeout: 1)

    assert_raises RuntimeError do
      client.get('eternium.orgizm.net', 1195, '/hello')
    end
  end

  def test_client_arguments
    # wrong port
    client = CoRE::CoAP::Client.new
    assert_raises Errno::ECONNREFUSED do
      client.get('coap.me', 15_683, '/hello')
    end

    # empty path
    client = CoRE::CoAP::Client.new
    assert_raises ArgumentError do
      answer = client.get('coap.me', 5683, '')
    end

    # empty host
    client = CoRE::CoAP::Client.new
    assert_raises ArgumentError do
      answer = client.get('', 15_683, '/hello')
    end

    # string port
    client = CoRE::CoAP::Client.new
    assert_raises ArgumentError do
      answer = client.get('coap.me', 'sring', '/hello')
    end

    # empty payload
    client = CoRE::CoAP::Client.new
    assert_raises ArgumentError do
      answer = client.post('coap.me', 5683, '/large-create', '')
    end
  end

  def test_client_get_by_uri
    client = CoRE::CoAP::Client.new
    answer = client.get_by_uri('coap://coap.me:5683/hello')
    assert_equal('world', answer.payload)

    # Broken URI
    client = CoRE::CoAP::Client.new
    assert_raises ArgumentError do
      answer = client.get_by_uri('coap:/#/coap.me:5683/hello')
    end
  end

  # TODO test payload

  def test_client_post
    client = CoRE::CoAP::Client.new
    answer = client.post('coap.me', 5683, '/test', 'TD_COAP_CORE_04')
    assert_equal([2, 1], answer.mcode)
    assert_equal('POST OK', answer.payload)
  end

  # basic test put
  def test_client_put
    client = CoRE::CoAP::Client.new
    answer = client.put('coap.me', 5683, '/test', 'TD_COAP_CORE_03')
    assert_equal([2, 4], answer.mcode)
    assert_equal('PUT OK', answer.payload)
  end

  def test_client_delete
    client = CoRE::CoAP::Client.new
    answer = client.delete('coap.me', 5683, '/test')
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
    answer = client.get(nil, nil, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    answer = client.get(nil, nil, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    answer = client.get(nil, nil, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    client = CoRE::CoAP::Client.new
    answer = client.get('coap.me', 5683, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    answer = client.get(nil, nil, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)

    answer = client.get(nil, nil, '/hello')
    assert_equal([2, 5], answer.mcode)
    assert_equal('world', answer.payload)
  end

  def test_initialize
    client = CoRE::CoAP::Client.new(host: 'coap.me', max_payload: 16)
    answer = client.get(nil, nil, '/large')
    assert_equal([2, 5], answer.mcode)
    assert_equal(%Q'\n     0                   1                   2                   3\n    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |Ver| T |  TKL  |      Code     |          Message ID           |\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Token (if any, TKL bytes) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Options (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |1 1 1 1 1 1 1 1|    Payload (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n\n[...]\n\n   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of\n      the variable-length Token field (0-8 bytes).  Lengths 9-15 are\n      reserved, MUST NOT be sent, and MUST be processed as a message\n      format error.\n\n   Code:  8-bit unsigned integer, split into a 3-bit class (most\n      significant bits) and a 5-bit detail (least significant bits),\n      documented as c.dd where c is a digit from 0 to 7 for the 3-bit\n      subfield and dd are two digits from 00 to 31 for the 5-bit\n      subfield.  The class can indicate a request (0), a success\n      response (2), a client error response (4), or a server error\n      response (5).  (All other class values are reserved.)  As a\n      special case, Code 0.00 indicates an Empty message.  In case of a\n      request, the Code field indicates the Request Method; in case of a\n      response a Response Code.  Possible values are maintained in the\n      CoAP Code Registries (Section 12.1).  The semantics of requests\n      and responses are defined in Section 5.\n\n', answer.payload)
  end

  def test_client_separate
    client = CoRE::CoAP::Client.new
    answer = client.get('coap.me', 5683, '/separate')
    assert_equal([2, 5], answer.mcode)
    assert_equal('That took a long time', answer.payload)
  end

  def test_client_observe
    client = CoRE::CoAP::Client.new

    t1 = Thread.new do
      client.observe('vs0.inf.ethz.ch', 5683, '/obs', method(:observe_tester))
    end

    old_value = @@observe_count
    sleep 0.25 while old_value == @@observe_count

    assert_operator @@observe_count, :>, old_value
  end

  def test_client_block1
    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.post('coap.me', 5683, '/large-create', PAYLOAD)
    assert_equal([2, 1], answer.mcode)

    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.get('coap.me', 5683, '/large-create')
    assert_equal([2, 5], answer.mcode)
    assert_equal(PAYLOAD, answer.payload)

    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.post('coap.me', 5683, '/large-create', PAYLOAD_UTF8)
    assert_equal([2, 1], answer.mcode)

    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.get('coap.me', 5683, '/large-create')
    assert_equal([2, 5], answer.mcode)
    assert_equal(PAYLOAD_UTF8, answer.payload.force_encoding('utf-8'))

    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.put('coap.me', 5683, '/large-update', PAYLOAD)
    assert_equal([2, 4], answer.mcode)

    client = CoRE::CoAP::Client.new(max_payload: 512)
    answer = client.get('coap.me', 5683, '/large-update')
    assert_equal([2, 5], answer.mcode)
    assert_equal(PAYLOAD, answer.payload)
  end

  def test_client_block2
    client = CoRE::CoAP::Client.new
    client.max_payload = 512
    answer = client.get('coap.me', 5683, '/large')
    assert_equal([2, 5], answer.mcode)
    assert_equal(%Q'\n     0                   1                   2                   3\n    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |Ver| T |  TKL  |      Code     |          Message ID           |\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Token (if any, TKL bytes) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |   Options (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n   |1 1 1 1 1 1 1 1|    Payload (if any) ...\n   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+\n\n[...]\n\n   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of\n      the variable-length Token field (0-8 bytes).  Lengths 9-15 are\n      reserved, MUST NOT be sent, and MUST be processed as a message\n      format error.\n\n   Code:  8-bit unsigned integer, split into a 3-bit class (most\n      significant bits) and a 5-bit detail (least significant bits),\n      documented as c.dd where c is a digit from 0 to 7 for the 3-bit\n      subfield and dd are two digits from 00 to 31 for the 5-bit\n      subfield.  The class can indicate a request (0), a success\n      response (2), a client error response (4), or a server error\n      response (5).  (All other class values are reserved.)  As a\n      special case, Code 0.00 indicates an Empty message.  In case of a\n      request, the Code field indicates the Request Method; in case of a\n      response a Response Code.  Possible values are maintained in the\n      CoAP Code Registries (Section 12.1).  The semantics of requests\n      and responses are defined in Section 5.\n\n', answer.payload)
  end
end
