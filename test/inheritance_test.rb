require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'xml/mapping'
require 'xml/xxpath_methods'

class Base
  attr_accessor :baseinit

  def initialize(p)
    self.baseinit = p
  end
end

class Derived < Base
  include XML::Mapping

  text_node :mytext, "mytext"
end

class Derived2 < Base
  include XML::Mapping

  text_node :baseinit, "baseinit"
end

# test that tries to reproduce ticket #4783
class InheritanceTest < Test::Unit::TestCase

  def test_inheritance_simple
    d = Derived.new "foo"
    assert_equal "foo", d.baseinit
    d.mytext = "hello"
    dxml=d.save_to_xml
    assert_equal "hello", dxml.first_xpath("mytext").text
    d2 = Derived.load_from_xml(dxml)
    assert_nil d2.baseinit
    assert_equal "hello", d2.mytext
  end

  def test_inheritance_superclass_initializing_mappedattr
    d = Derived2.new "foo"
    assert_equal "foo", d.baseinit
    dxml=d.save_to_xml
    assert_equal "foo", dxml.first_xpath("baseinit").text
    d2 = Derived2.load_from_xml(dxml)
    assert_equal "foo", d2.baseinit
  end

end
