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

end
