require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'triangle_mm'

require 'xml/xxpath_methods'

module XML::Mapping
  def ==(other)
    Marshal.dump(self) == Marshal.dump(other)
  end
end

class MultipleMappingsTest < Test::Unit::TestCase
  def setup
  end

  def test_read
    t1=Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m1
    assert_raises(XML::MappingError) do
      Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m2
    end
    t2=Triangle.load_from_file File.dirname(__FILE__) + "/fixtures/triangle_m2.xml", :mapping=>:m2

    t=Triangle.new('tri1','green',
                   Point.new(3,0),Point.new(2,4),Point.new(0,1))

    assert_equal t, t1
    assert_equal t, t2
    assert_equal t1, t2
    assert_not_equal Triangle.allocate, t

    # using default mapping should produce empty objects
    assert_equal Triangle.allocate,
                 Triangle.load_from_file(File.dirname(__FILE__) + "/fixtures/triangle_m1.xml")
    assert_equal Triangle.allocate,
                 Triangle.load_from_file(File.dirname(__FILE__) + "/fixtures/triangle_m2.xml")
  end


  def test_read_polymorphic
    t1=XML::Mapping.load_object_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m1
    t2=XML::Mapping.load_object_from_file File.dirname(__FILE__) + "/fixtures/triangle_m2.xml", :mapping=>:m2
    t=Triangle.new('tri1','green',
                   Point.new(3,0),Point.new(2,4),Point.new(0,1))

    assert_equal t, t1
    assert_equal t, t2
    assert_equal t1, t2
  end


  def test_write
    t1=XML::Mapping.load_object_from_file File.dirname(__FILE__) + "/fixtures/triangle_m1.xml", :mapping=>:m1
    m1xml = t1.save_to_xml :mapping=>:m1
    m2xml = t1.save_to_xml :mapping=>:m2

    assert_equal t1.name, m1xml.first('@name').text
    # TODO: more tests...
  end

end
