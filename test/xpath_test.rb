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
    assert_equal @d.root.elements.to_a("foo"), XML::XPath.new("foo").all(@d.root)
    assert_equal @d.root.elements.to_a("foo")[1].elements.to_a("u"), XML::XPath.new("foo/u").all(@d.root)
    assert_equal [], XML::XPath.new("foo/notthere").all(@d.root)
  end


  def test_read_byidx
    assert_equal [@d.root.elements[1]], XML::XPath.new("foo[1]").all(@d.root)
    assert_equal [@d.root.elements[3]], XML::XPath.new("foo[2]").all(@d.root)
    assert_equal [], XML::XPath.new("foo[10]").all(@d.root)
    assert_equal [], XML::XPath.new("foo[3]").all(@d.root)
  end


  def test_read_byall
    assert_equal @d.root.elements.to_a, XML::XPath.new("*").all(@d.root)
    assert_equal [], XML::XPath.new("notthere/*").all(@d.root)
  end


  def test_read_byattr
    assert_equal [@d.root.elements[3]], XML::XPath.new("foo[@key='xy']").all(@d.root)
    assert_equal [], XML::XPath.new("foo[@key='notthere']").all(@d.root)
    assert_equal [], XML::XPath.new("notthere[@key='xy']").all(@d.root)
  end


  def test_attribute
    elt = @d.root.elements[3]
    attr1 = XML::XPath::Accessors::Attribute.new(elt,"key",false)
    attr2 = XML::XPath::Accessors::Attribute.new(elt,"key",false)
    assert_not_nil attr1
    assert_not_nil attr2
    assert_equal attr1,attr2  # tests Attribute.==
    assert_nil XML::XPath::Accessors::Attribute.new(elt,"notthere",false)
    assert_nil XML::XPath::Accessors::Attribute.new(elt,"notthere",false)
    newattr = XML::XPath::Accessors::Attribute.new(elt,"new",true)
    assert_not_nil newattr
    assert_equal newattr, XML::XPath::Accessors::Attribute.new(elt,"new",false)
    newattr.text = "lala"
    assert_equal "lala", elt.attributes["new"]
  end

  def test_read_byattrname
    assert_equal [XML::XPath::Accessors::Attribute.new(@d.root.elements[3],"key",false)],
                 XML::XPath.new("foo/@key").all(@d.root)
    assert_equal [], XML::XPath.new("foo/@notthere").all(@d.root)
  end


  def test_read_byidx_then_name
    assert_equal [@d.root.elements[3].elements[1]], XML::XPath.new("foo[2]/u").all(@d.root)
    assert_equal [], XML::XPath.new("foo[2]/notthere").all(@d.root)
    assert_equal [], XML::XPath.new("notthere[2]/u").all(@d.root)
    assert_equal [], XML::XPath.new("foo[3]/u").all(@d.root)
  end

  def test_read_first
    assert_equal @d.root.elements[3].elements[1], XML::XPath.new("foo[2]/u").first(@d.root)
  end

  def test_read_first_nil
    assert_equal nil, XML::XPath.new("foo[2]/notthere").first(@d.root,false,true)
  end

  def test_read_first_exception
    assert_raises(XML::XPathError) {
      XML::XPath.new("foo[2]/notthere").first(@d.root)
    }
  end


  def test_write_noop
    assert_equal @d.root.elements[1], XML::XPath.new("foo").first(@d.root,true)
    assert_equal @d.root.elements[3].elements[1], XML::XPath.new("foo[2]/u").first(@d.root,true)
    # TODO: deep-compare of REXML documents?
  end

  def test_write_byname_then_name
    s1 = @d.elements[1].elements.size
    s2 = @d.elements[1].elements[1].elements.size
    node = XML::XPath.new("foo/new1").first(@d.root,true)
    assert_equal "new1", node.name
    assert node.attributes.empty?
    assert_equal @d.elements[1].elements[1].elements[1], node
    assert_equal s1, @d.elements[1].elements.size
    assert_equal s2+1, @d.elements[1].elements[1].elements.size
  end


  def test_write_byidx
    XML::XPath.new("foo[2]").first(@d.root,true)
    # TODO: deep-compare of REXML documents?
    assert_equal 2, @d.root.elements.select{|elt| elt.name=="foo"}.size
    node = XML::XPath.new("foo[10]").first(@d.root,true)
    assert_equal 10, @d.root.elements.select{|elt| elt.name=="foo"}.size
    assert_equal "foo", node.name
  end


  def test_write_byattrname
    elt = @d.root.elements[3]
    s1 = elt.attributes.size
    attr_key = XML::XPath.new("foo[2]/@key").first(@d.root,true)
    assert_equal elt.attributes["key"], attr_key.text

    attr_new = XML::XPath.new("foo[2]/@new").first(@d.root,true)
    attr_new.text = "haha"
    assert_equal "haha", attr_new.text
    assert_equal "haha", elt.attributes["new"]
    assert_equal s1+1, elt.attributes.size
  end

end
