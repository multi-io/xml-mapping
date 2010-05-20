require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'

require "rexml/document"
require "xml/xxpath_methods"


class XXPathMethodsTest < Test::Unit::TestCase
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

  def test_first_xpath
    pathstr = "foo[2]/u"
    path = XML::XXPath.new(pathstr)
    elt = path.first(@d.root)
    assert_equal elt, @d.root.first_xpath(pathstr)
    assert_equal elt, @d.root.first_xpath(path)
  end

  def test_all_xpath
    pathstr = "foo"
    path = XML::XXPath.new(pathstr)
    elts = path.all(@d.root)
    assert_equal elts, @d.root.all_xpath(pathstr)
    assert_equal elts, @d.root.all_xpath(path)
  end

  def test_each_xpath
    pathstr = "foo"
    path = XML::XXPath.new(pathstr)
    elts = []
    path.each(@d.root) do |elt|
      elts << elt
    end
    elts_actual = []
    @d.root.each_xpath(pathstr) do |elt|
      elts_actual << elt
    end
    assert_equal elts, elts_actual
  end

  def test_create_new
    @d.root.create_new_xpath("foo")
    @d.root.create_new_xpath(XML::XXPath.new("foo"))
    assert_equal 4, @d.root.elements.to_a("foo").size
  end

end
