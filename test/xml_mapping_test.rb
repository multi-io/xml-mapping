require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'company'

module XML::Mapping
  def ==(other)
    Marshal.dump(self) == Marshal.dump(other)
  end
end

class XmlMappingTest < Test::Unit::TestCase
  def setup
    # need to undo mapping class definitions that may have been
    # established by other tests
    XML::Mapping.module_eval <<-EOS
      Classes_w_default_rootelt_names.clear
    EOS
    Object.send(:remove_const, "Company")
    Object.send(:remove_const, "Address")
    Object.send(:remove_const, "Office")
    Object.send(:remove_const, "Customer")
    $".delete "company.rb"
    $:.unshift File.dirname(__FILE__)  # test/unit may have undone this (see test/unit/collector/dir.rb)
    require 'company'

    @xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/company1.xml"))
    @c = Company.load_from_xml(@xml.root)
  end

  def test_getter_text_node
    assert_equal "bar", @c.ent2
  end

  def test_getter_int_node
    assert_equal 18, @c.offices[1].address.number
  end

  def test_getter_boolean_node
    path=XML::XPath.new("offices/office[2]/classified")
    assert_equal(path.first(@xml.root).text == "yes",
                 @c.offices[1].classified)
  end

  def test_getter_hash_node
    assert_equal 4, @c.customers.keys.size
    ["cm", "ernie", "jim", "sad"].zip(@c.customers.keys.sort).each do |exp,ckey|
      assert_equal exp, ckey
      assert_equal exp, @c.customers[ckey].uid
    end
  end

  def test_getter_array_node
    assert_equal ["pencils", "weapons of mass destruction"],
          @c.offices.map{|o|o.speciality}
  end


  def test_setter_text_node
    @c.ent2 = "lalala"
    assert_equal "lalala", REXML::XPath.first(@c.save_to_xml, "arrtest/entry[2]").text
  end


  def test_setter_array_node
    xml=@c.save_to_xml
    assert_equal ["pencils", "weapons of mass destruction"],
          XML::XPath.new("offices/office/@speciality").all(xml).map{|n|n.text}
  end


  def test_setter_hash_node
    xml=@c.save_to_xml
    assert_equal @c.customers.keys.sort,
          XML::XPath.new("customers/customer/@uid").all(@xml.root).map{|n|n.text}.sort
  end


  def test_setter_boolean_node
    @c.offices[0].classified = !@c.offices[0].classified
    xml=@c.save_to_xml
    assert_equal @c.offices[0].classified,
          XML::XPath.new("offices/office[1]/classified").first(xml).text == "yes"
  end


  def test_root_element
    assert_equal @c, XML::Mapping.load_object_from_file(File.dirname(__FILE__) + "/fixtures/company1.xml")
    assert_equal @c, XML::Mapping.load_object_from_xml(@xml.root)

    assert_equal "company", Company.root_element_name
    assert_equal Company, XML::Mapping.class_for_root_elt_name("company")
    xml=@c.save_to_xml
    assert_equal "company", xml.name
    # Company.root_element_name 'my-test'
    Company.class_eval <<-EOS
        root_element_name 'my-test'
    EOS
    assert_equal "my-test", Company.root_element_name
    assert_equal Company, XML::Mapping.class_for_root_elt_name("my-test")
    assert_nil XML::Mapping.class_for_root_elt_name("company")
    xml=@c.save_to_xml
    assert_equal "my-test", xml.name
    assert_equal "office", @c.offices[0].save_to_xml.name

    assert_raises(XML::MappingError) {
      XML::Mapping.load_object_from_xml @xml.root
    }
    @xml.root.name = 'my-test'
    assert_equal @c, XML::Mapping.load_object_from_xml(@xml.root)

    # white-box tests
    assert_equal [["my-test", Company]], XML::Mapping::Classes_w_nondefault_rootelt_names.sort
    assert_equal [["address", Address], ["customer", Customer], ["office", Office]],
          XML::Mapping::Classes_w_default_rootelt_names.sort
  end


  def test_optional_flag
    hamburg_address_path = XML::XPath.new("offices/office[1]/address")
    baghdad_address_path = XML::XPath.new("offices/office[2]/address")
    hamburg_zip_path = XML::XPath.new("offices/office[1]/address/zip")
    baghdad_zip_path = XML::XPath.new("offices/office[2]/address/zip")

    assert_equal 18282, @c.offices[0].address.zip
    assert_equal 12576, @c.offices[1].address.zip
    xml=@c.save_to_xml
    assert_equal "18282", hamburg_zip_path.first(xml).text
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)
    @c.offices[1].address.zip = 12577
    xml=@c.save_to_xml
    assert_equal "12577", baghdad_zip_path.first(xml).text
    c2 = Company.load_from_xml(xml)
    assert_equal 12577, c2.offices[1].address.zip
    @c.offices[1].address.zip = 12576
    xml=@c.save_to_xml
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)

    hamburg_address_path.first(xml).delete_element("zip")
    c3 = Company.load_from_xml(xml)
    assert_equal 12576, c3.offices[0].address.zip
    hamburg_address_path.first(xml).delete_element("city")
    assert_raises(XML::MappingError) {
      Company.load_from_xml(xml)
    }
  end


  def test_optional_flag_nodefault
    hamburg_address_path = XML::XPath.new("offices/office[1]/address")
    hamburg_street_path = XML::XPath.new("offices/office[1]/address/street")

    assert_equal hamburg_street_path.first(@xml.root).text,
          @c.offices[0].address.street

    hamburg_address_path.first(@xml.root).delete_element("street")
    c2 = Company.load_from_xml(@xml.root)
    assert_nil c2.offices[0].address.street

    xml2=c2.save_to_xml
    assert_nil hamburg_street_path.first(xml2,:allow_nil=>true)
  end


  def test_polymorphic_node
    assert_equal 3, @c.stuff.size
    assert_equal 'Saddam Hussein', @c.stuff[0].name
    assert_equal 'Berlin', @c.stuff[1].city
    assert_equal 'weapons of mass destruction', @c.stuff[2].speciality

    @c.stuff[1].city = 'Munich'
    @c.stuff[2].classified = false

    xml2=@c.save_to_xml
    assert_equal 'Munich', xml2.root.elements[5].elements[2].elements[1].text
    assert_equal 'no',     xml2.root.elements[5].elements[3].elements[1].text
  end

end
