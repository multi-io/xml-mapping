require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'triangle_mm'

module XML::Mapping
  def ==(other)
    Marshal.dump(self) == Marshal.dump(other)
  end
end

class MultipleMappingsTest < Test::Unit::TestCase
  def setup
  end

  def test_simple
    t1=Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m1
    assert_raises(XML::MappingError) do
      Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m2
    end
    t2=Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m2.xml", :mapping=>:m2

    t=Triangle.new('tri1','green',
                   Point.new(3,0),Point.new(2,4),Point.new(0,1))

    assert_equal(t,t1)
    assert_equal(t,t2)
    assert_equal(t1,t2)
    assert_not_equal(t, Triangle.allocate)
  end
end
