require File.dirname(__FILE__) + '/../test_helper'

require "rexml/document"
require "xml/xpath"


class XPathTest < Test::Unit::TestCase
  include REXML

  def setup
    @d = Document.new <<-EOS
    <bla>
      <foo>x</foo>
      <bar>bar1</bar>
      <foo key='xy'>
        y
        <u/>
      </foo>
    </bla>
    EOS
  end

  def test_read_byname
    foores = XML::XPath.new("foo").all(@d.root)
    assert_equal @d.root.elements.to_a("foo"), foores

    fooures = XML::XPath.new("foo/u").all(@d.root)
    assert_equal @d.root.elements.to_a("foo")[1].elements.to_a("u"), fooures
  end


  def test_read_byidx
    assert_equal [@d.root.elements[1]], XML::XPath.new("foo[1]").all(@d.root)
    assert_equal [@d.root.elements[3]], XML::XPath.new("foo[2]").all(@d.root)
  end


  def test_read_byall
    assert_equal @d.root.elements.to_a, XML::XPath.new("*").all(@d.root)
  end


  def test_read_byattr
    assert_equal [@d.root.elements[3]], XML::XPath.new("foo[@key='xy']").all(@d.root)
  end


  def test_read_byidx_then_name
    assert_equal [@d.root.elements[3].elements[1]], XML::XPath.new("foo[2]/u").all(@d.root)
  end

  def test_read_notfound
    assert_equal [], XML::XPath.new("foo[2]/notthere").all(@d.root)
  end

  def test_read_first
    assert_equal @d.root.elements[3].elements[1], XML::XPath.new("foo[2]/u").first(@d.root)
  end

  def test_read_first_nil
    assert_equal nil, XML::XPath.new("foo[2]/notthere").first(@d.root,false,true)
  end

  def test_read_first_exception
    begin
      assert_equal nil, XML::XPath.new("foo[2]/notthere").first(@d.root)
      fail "XML::XPathError expected"
    rescue XML::XPathError => err
      # print "ok, received: #{err.message}\n"
    end
  end



end
