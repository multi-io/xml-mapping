require File.dirname(__FILE__) + '/../test_helper'

require "rexml/document"
require "xml/xpath"


class XmlMappingTest < Test::Unit::TestCase
  include REXML

  def test_read_byname
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo>y<u/></foo></bla>"

    foores = XML::XPath.new("foo").all(d.root)
    assert_equal d.root.elements.to_a("foo"), foores

    fooures = XML::XPath.new("foo/u").all(d.root)
    assert_equal d.root.elements.to_a("foo")[1].elements.to_a("u"), fooures
  end


  def test_read_byidx
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo key='xy'>y<u/></foo></bla>"
    assert_equal [d.root.elements[1]], XML::XPath.new("foo[1]").all(d.root)
    assert_equal [d.root.elements[3]], XML::XPath.new("foo[2]").all(d.root)
  end


  def test_read_byall
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo key='xy'>y<u/></foo></bla>"
    assert_equal d.root.elements.to_a, XML::XPath.new("*").all(d.root)
  end


  def test_read_byattr
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo key='xy'>y<u/></foo></bla>"
    assert_equal [d.root.elements[3]], XML::XPath.new("foo[@key='xy']").all(d.root)
  end


  def test_read_byidx_then_name
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo>y<u/></foo></bla>"
    assert_equal [d.root.elements[3].elements[1]], XML::XPath.new("foo[2]/u").all(d.root)
  end

end
