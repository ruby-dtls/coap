# encoding: utf-8

require_relative 'helper'

class TestMessage < Minitest::Test
  def test_number_of_bits_up_to
    assert_equal 0, CoRE::CoAP.number_of_bits_up_to(1)
    assert_equal 4, CoRE::CoAP.number_of_bits_up_to(16)
    assert_equal 5, CoRE::CoAP.number_of_bits_up_to(32)
    assert_equal 7, CoRE::CoAP.number_of_bits_up_to(128)
  end

  def test_path_encode
    assert_equal "/", CoRE::CoAP.path_encode([])
    assert_equal "/foo", CoRE::CoAP.path_encode(["foo"])
    assert_equal "/foo/bar", CoRE::CoAP.path_encode(["foo", "bar"])
    assert_equal "/f.o/b-r", CoRE::CoAP.path_encode(["f.o", "b-r"])
    assert_equal "/f(o/b)r", CoRE::CoAP.path_encode(["f(o", "b)r"])
    assert_equal "/foo/b%2Fr", CoRE::CoAP.path_encode(["foo", "b/r"])
    assert_equal "/foo/b&r", CoRE::CoAP.path_encode(["foo", "b&r"])
    assert_equal "/f%C3%B8o/b%C3%A4r", CoRE::CoAP.path_encode(["føo", "bär"])
  end

  def test_query_encode
    assert_equal "", CoRE::CoAP.query_encode([])
    assert_equal "?", CoRE::CoAP.query_encode([""])
    assert_equal "?foo", CoRE::CoAP.query_encode(["foo"])
    assert_equal "?foo&bar", CoRE::CoAP.query_encode(["foo", "bar"])
    assert_equal "?f.o&b-r", CoRE::CoAP.query_encode(["f.o", "b-r"])
    assert_equal "?f(o&b)r", CoRE::CoAP.query_encode(["f(o", "b)r"])
    assert_equal "?foo&b/r", CoRE::CoAP.query_encode(["foo", "b/r"])
    assert_equal "?foo&b%26r", CoRE::CoAP.query_encode(["foo", "b&r"])
    assert_equal "?f%C3%B8o&b%C3%A4r", CoRE::CoAP.query_encode(["føo", "bär"])
  end

  # XXX: now properly checks for trailing slashes, how much trouble?
  def test_path_decode
    assert_equal [], CoRE::CoAP.path_decode("/")
    assert_equal ["foo"], CoRE::CoAP.path_decode("/foo")
    assert_equal ["foo", ""], CoRE::CoAP.path_decode("/foo/") # confusing!
    assert_equal ["foo", "bar"], CoRE::CoAP.path_decode("/foo/bar")
    assert_equal ["f.o", "b-r"], CoRE::CoAP.path_decode("/f.o/b-r")
    assert_equal ["f(o", "b)r"], CoRE::CoAP.path_decode("/f(o/b)r")
    assert_equal ["foo", "b/r"], CoRE::CoAP.path_decode("/foo/b%2Fr")
    assert_equal ["foo", "b&r"], CoRE::CoAP.path_decode("/foo/b&r")
    assert_equal ["føo", "bär"], CoRE::CoAP.path_decode("/f%C3%B8o/b%C3%A4r")
  end

  # XXX: now checks for trailing ampersands
  def test_query_decode
    assert_equal [], CoRE::CoAP.query_decode("")
    assert_equal [""], CoRE::CoAP.query_decode("?")
    assert_equal ["foo"], CoRE::CoAP.query_decode("?foo")
    assert_equal ["foo", ""], CoRE::CoAP.query_decode("?foo&")
    assert_equal ["foo", "bar"], CoRE::CoAP.query_decode("?foo&bar")
    assert_equal ["f.o", "b-r"], CoRE::CoAP.query_decode("?f.o&b-r")
    assert_equal ["f(o", "b)r"], CoRE::CoAP.query_decode("?f(o&b)r")
    assert_equal ["foo", "b/r"], CoRE::CoAP.query_decode("?foo&b/r")
    assert_equal ["foo", "b&r"], CoRE::CoAP.query_decode("?foo&b%26r")
    assert_equal ["føo", "bär"], CoRE::CoAP.query_decode("?f%C3%B8o&b%C3%A4r")
  end

  def test_scheme_and_authority_encode
    assert_equal "coap://foo.bar:4711", CoRE::CoAP.scheme_and_authority_encode("foo.bar", 4711)
    assert_equal "coap://foo.bar:4711", CoRE::CoAP.scheme_and_authority_encode("foo.bar", "4711")
    assert_raises ArgumentError do
      CoRE::CoAP.scheme_and_authority_encode("foo.bar", "baz")
    end
    assert_equal "coap://bar.baz", CoRE::CoAP.scheme_and_authority_encode("bar.baz", 5683)
    assert_equal "coap://bar.baz", CoRE::CoAP.scheme_and_authority_encode("bar.baz", "5683")
  end

  def test_scheme_and_authority_decode
    assert_equal [nil, "foo.bar", 4711], CoRE::CoAP.scheme_and_authority_decode("coap://foo.bar:4711")
    assert_equal [nil, "foo.bar", 5683], CoRE::CoAP.scheme_and_authority_decode("coap://foo.bar")
    assert_equal [nil, "foo:bar", 4711], CoRE::CoAP.scheme_and_authority_decode("coap://[foo:bar]:4711")
    assert_equal [nil, "foo:bar", 5683], CoRE::CoAP.scheme_and_authority_decode("coap://%5Bfoo:bar%5D")
  end

  def test_coap_message
    input = "\x44\x02\x12\xA0abcd\x41A\x7B.well-known\x04core\x0D\x04rhabarbersaftglas\xFFfoobar".force_encoding("BINARY")
    Log.debug input.hexdump('input ')
    output = CoRE::CoAP.parse(input)
    Log.debug output
    Log.debug "critical?: #{output.options.map { |k, v| [k, CoRE::CoAP.critical?(k)]}.inspect}"
    w = output.to_wire
    Log.debug w.hexdump('output ')
    assert_equal input, w
  end

  # XXX TODO add token tests

  def test_fenceposting
    m = CoRE::CoAP::Message.new(:con, :get, 4711, "Hello")
    Log.debug m
    m.options = { max_age: 987654321, if_none_match: true }
    Log.debug m
    me = m.to_wire
    Log.debug me.inspect
    m2 = CoRE::CoAP::parse(me)
    Log.debug m2
    m.options = CoRE::CoAP::DEFAULTING_OPTIONS.merge(m.options)
    assert_equal m2, m
  end

  def test_fenceposting2
    m = CoRE::CoAP::Message.new(:con, :get, 4711, "Hello")
    Log.debug m
    m.options = { 4711 => ["foo"], 256 => ["bar"] }
    Log.debug m
    me = m.to_wire
    Log.debug me.inspect
    m2 = CoRE::CoAP::parse(me)
    Log.debug m2
    m.options = CoRE::CoAP::DEFAULTING_OPTIONS.merge(m.options)
    assert_equal m2, m
  end

  def test_emptypayload
    m = CoRE::CoAP::Message.new(:con, :get, 4711, "")
    Log.debug m
    m.options = { 4711 => ["foo"], 256 => ["bar"], 65535 => ["abc" * 100] }
    Log.debug m
    me = m.to_wire
    Log.debug me.inspect
    m2 = CoRE::CoAP::parse(me)
    Log.debug m2
    m.options = CoRE::CoAP::DEFAULTING_OPTIONS.merge(m.options)
    assert_equal m2, m
  end

  def test_option_numbers
    (0...65536).each do |on|
      unless CoRE::CoAP::OPTIONS[on] # those might have special semantics
        m = CoRE::CoAP::Message.new(:con, :get, 4711, "Hello")
        m.options = { on => [""] }
        me = m.to_wire
        m2 = CoRE::CoAP::parse(me)
        m.options = CoRE::CoAP::DEFAULTING_OPTIONS.merge(m.options)
        assert_equal m2, m
      end
    end
  end

  def test_option_lengths
    (0...1035).each do |ol|
      m = CoRE::CoAP::Message.new(:con, :get, 4711, "Hello")
      m.options = { 99 => ["x"*ol] }
      me = m.to_wire
      m2 = CoRE::CoAP::parse(me)
      m.options = CoRE::CoAP::DEFAULTING_OPTIONS.merge(m.options)
      assert_equal m2, m
    end
  end
end
