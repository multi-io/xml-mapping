require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'

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
    assert_equal nil, XML::XPath.new("foo[2]/notthere").first(@d.root, :allow_nil=>true)
  end

  def test_read_first_exception
    assert_raises(XML::XPathError) {
      XML::XPath.new("foo[2]/notthere").first(@d.root)
    }
  end


  def test_write_noop
    assert_equal @d.root.elements[1], XML::XPath.new("foo").first(@d.root, :ensure_created=>true)
    assert_equal @d.root.elements[3].elements[1], XML::XPath.new("foo[2]/u").first(@d.root, :ensure_created=>true)
    # TODO: deep-compare of REXML documents?
  end

  def test_write_byname_then_name
    s1 = @d.elements[1].elements.size
    s2 = @d.elements[1].elements[1].elements.size
    node = XML::XPath.new("foo/new1").first(@d.root, :ensure_created=>true)
    assert_equal "new1", node.name
    assert node.attributes.empty?
    assert_equal @d.elements[1].elements[1].elements[1], node
    assert_equal s1, @d.elements[1].elements.size
    assert_equal s2+1, @d.elements[1].elements[1].elements.size
  end


  def test_write_byidx
    XML::XPath.new("foo[2]").first(@d.root, :ensure_created=>true)
    # TODO: deep-compare of REXML documents?
    assert_equal 2, @d.root.elements.select{|elt| elt.name=="foo"}.size
    node = XML::XPath.new("foo[10]").first(@d.root, :ensure_created=>true)
    assert_equal 10, @d.root.elements.select{|elt| elt.name=="foo"}.size
    assert_equal "foo", node.name
  end


  def test_write_byattrname
    elt = @d.root.elements[3]
    s1 = elt.attributes.size
    attr_key = XML::XPath.new("foo[2]/@key").first(@d.root, :ensure_created=>true)
    assert_equal elt.attributes["key"], attr_key.text

    attr_new = XML::XPath.new("foo[2]/@new").first(@d.root, :ensure_created=>true)
    attr_new.text = "haha"
    assert_equal "haha", attr_new.text
    assert_equal "haha", elt.attributes["new"]
    assert_equal s1+1, elt.attributes.size
  end


  def test_create_new_byname
    s1 = @d.elements[1].elements.size
    s2 = @d.elements[1].elements[1].elements.size
    startnode = @d.elements[1].elements[1]
    node1 = XML::XPath.new("new1").create_new(startnode)
    node2 = XML::XPath.new("new1").first(startnode, :create_new=>true) #same as .create_new(...)
    assert_equal "new1", node1.name
    assert_equal "new1", node2.name
    assert node1.attributes.empty?
    assert node2.attributes.empty?
    assert_equal @d.elements[1].elements[1].elements[1], node1
    assert_equal @d.elements[1].elements[1].elements[2], node2
    assert_equal s1, @d.elements[1].elements.size
    assert_equal s2+2, @d.elements[1].elements[1].elements.size
  end


  def test_create_new_byname_then_name
    s1 = @d.elements[1].elements.size
    node1 = XML::XPath.new("foo/new1").create_new(@d.root)
    node2 = XML::XPath.new("foo/new1").create_new(@d.root)
    assert_equal "new1", node1.name
    assert_equal "new1", node2.name
    assert node1.attributes.empty?
    assert node2.attributes.empty?
    assert_equal @d.elements[1].elements[s1+1].elements[1], node1
    assert_equal @d.elements[1].elements[s1+2].elements[1], node2
    assert_equal s1+2, @d.elements[1].elements.size
  end


  def test_create_new_byidx
    assert_raises(XML::XPathError) {
      XML::XPath.new("foo[2]").create_new(@d.root)
    }
    node1 = XML::XPath.new("foo[3]").create_new(@d.root)
    assert_raises(XML::XPathError) {
      XML::XPath.new("foo[3]").create_new(@d.root)
    }
    assert_equal @d.elements[1].elements[4], node1
    assert_equal "foo", node1.name
    node2 = XML::XPath.new("foo[4]").create_new(@d.root)
    assert_equal @d.elements[1].elements[5], node2
    assert_equal "foo", node2.name
    node3 = XML::XPath.new("foo[10]").create_new(@d.root)
    assert_raises(XML::XPathError) {
      XML::XPath.new("foo[10]").create_new(@d.root)
    }
    XML::XPath.new("foo[11]").create_new(@d.root)
    assert_equal @d.elements[1].elements[11], node3
    assert_equal "foo", node3.name
    # @d.write
  end

  def test_create_new_byname_then_idx
    node1 = XML::XPath.new("hello/bar[3]").create_new(@d.root)
    node2 = XML::XPath.new("hello/bar[3]").create_new(@d.root)
      # same as create_new
    node3 = XML::XPath.new("hello/bar[3]").create_new(@d.root)
    assert_equal @d.elements[1].elements[4].elements[3], node1
    assert_equal @d.elements[1].elements[5].elements[3], node2
    assert_equal @d.elements[1].elements[6].elements[3], node3
    assert_not_equal node1, node2
    assert_not_equal node1, node3
    assert_not_equal node2, node3
  end


  def test_create_new_byattrname
    node1 = XML::XPath.new("@lala").create_new(@d.root)
    assert_raises(XML::XPathError) {
      XML::XPath.new("@lala").create_new(@d.root)
    }
    assert node1.kind_of?(XML::XPath::Accessors::Attribute)
    node1.text = "val1"
    assert_equal "val1", @d.elements[1].attributes["lala"]
    foo2 = XML::XPath.new("foo[2]").first(@d.root)
    assert_raises(XML::XPathError) {
      XML::XPath.new("@key").create_new(foo2)
    }
    node2 = XML::XPath.new("@bar").create_new(foo2)
    assert node2.kind_of?(XML::XPath::Accessors::Attribute)
    node2.text = "val2"
    assert_equal "val2", @d.elements[1].elements[3].attributes["bar"]
  end

end
