require File.dirname(__FILE__) + '/../test_helper'

require "rexml/document"
require "xml/xpath"


class XmlMappingTest < Test::Unit::TestCase
  include REXML

  def test_byname
    d = Document.new "<bla><foo>x</foo><bar>bar1</bar><foo>y<u/></foo></bla>"

    foores = XML::XPath.new("foo").all(d.root)
    assert_equal 2, foores.size
    assert_equal foores[0], d.root.elements.to_a("foo")[0]
    assert_equal foores[1], d.root.elements.to_a("foo")[1]

    fooures = XML::XPath.new("foo/u").all(d.root)
    assert_equal 1, fooures.size
    assert_equal fooures[0], d.root.elements.to_a("foo")[1].elements.to_a("u")[0]
  end

end
