require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'company'

class XmlMappingTest < Test::Unit::TestCase
  def setup
    @xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/company1.xml"))
    @c = Company.load_from_rexml(@xml.root)
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
      assert_equal exp, @c.customers[ckey].id
    end
  end

  def test_getter_array_node
    assert_equal ["pencils", "weapons of mass destruction"],
          @c.offices.map{|o|o.speciality}
  end


  def test_setter_text_node
    @c.ent2 = "lalala"
    assert_equal "lalala", REXML::XPath.first(@c.save_to_rexml, "arrtest/entry[2]").text
  end


  def test_setter_array_node
    xml=@c.save_to_rexml
    assert_equal ["pencils", "weapons of mass destruction"],
          XML::XPath.new("offices/office/@speciality").all(xml).map{|n|n.text}
  end


  def test_setter_hash_node
    xml=@c.save_to_rexml
    assert_equal @c.customers.keys.sort,
          XML::XPath.new("customers/customer/@id").all(@xml.root).map{|n|n.text}.sort
  end


  def test_setter_boolean_node
    @c.offices[0].classified = !@c.offices[0].classified
    xml=@c.save_to_rexml
    assert_equal @c.offices[0].classified,
          XML::XPath.new("offices/office[1]/classified").first(xml).text == "yes"
  end


  def test_root_element
    xml=@c.save_to_rexml
    assert_equal "company", xml.name
    Company.class_eval <<-EOS
        root_element_name 'my-test'
    EOS
    xml=@c.save_to_rexml
    assert_equal "my-test", xml.name
    assert_equal "office", @c.offices[0].save_to_rexml.name
  end


  def test_optional_flag
    hamburg_address_path = XML::XPath.new("offices/office[1]/address")
    baghdad_address_path = XML::XPath.new("offices/office[2]/address")
    hamburg_zip_path = XML::XPath.new("offices/office[1]/address/zip")
    baghdad_zip_path = XML::XPath.new("offices/office[2]/address/zip")

    assert_equal 18282, @c.offices[0].address.zip
    assert_equal 12576, @c.offices[1].address.zip
    xml=@c.save_to_rexml
    assert_equal "18282", hamburg_zip_path.first(xml).text
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)
    @c.offices[1].address.zip = 12577
    xml=@c.save_to_rexml
    assert_equal "12577", baghdad_zip_path.first(xml).text
    c2 = Company.load_from_rexml(xml)
    assert_equal 12577, c2.offices[1].address.zip
    @c.offices[1].address.zip = 12576
    xml=@c.save_to_rexml
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)

    hamburg_address_path.first(xml).delete_element("zip")
    c3 = Company.load_from_rexml(xml)
    assert_equal 12576, c3.offices[0].address.zip
    hamburg_address_path.first(xml).delete_element("city")
    assert_raises(XML::MappingError) {
      Company.load_from_rexml(xml)
    }
  end


  def test_optional_flag_nodefault
    hamburg_address_path = XML::XPath.new("offices/office[1]/address")
    hamburg_street_path = XML::XPath.new("offices/office[1]/address/street")

    assert_equal hamburg_street_path.first(@xml.root).text,
          @c.offices[0].address.street

    hamburg_address_path.first(@xml.root).delete_element("street")
    c2 = Company.load_from_rexml(@xml.root)
    assert_nil c2.offices[0].address.street

    xml2=c2.save_to_rexml
    assert_nil hamburg_street_path.first(xml2,:allow_nil=>true)
  end

end
