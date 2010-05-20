#:invisible:
$:.unshift "../lib"
begin
  Object.send(:remove_const, "Address")  # remove any previous definitions
  Object.send(:remove_const, "Person")  # remove any previous definitions
rescue
end
#<=
#:visible:
require 'xml/mapping'

class Address; end

class Person
  include XML::Mapping

  # the default mapping. Stores the name and age in XML attributes,
  # and the address in a sub-element "address".

  text_node :name, "@name"
  numeric_node :age, "@age"
  object_node :address, "address", :class=>Address

  use_mapping :other

  # the ":other" mapping. Non-default root element name; name and age
  # stored in XML elements; address stored in the person's element
  # itself

  root_element_name "individual"
  text_node :name, "name"
  numeric_node :age, "age"
  object_node :address, ".", :class=>Address

  # you could also specify the mapping on a per-node basis with the
  # :mapping option, e.g.:
  #
  # numeric_node :age, "age", :mapping=>:other
end


class Address
  include XML::Mapping

  # the default mapping.

  text_node :street, "street"
  numeric_node :number, "number"
  text_node :city, "city"
  numeric_node :zip, "zip"

  use_mapping :other

  # the ":other" mapping.

  text_node :street, "street-name"
  numeric_node :number, "street-name/@number"
  text_node :city, "city-name"
  numeric_node :zip, "city-name/@zip-code"
end


### usage

## XML representation of a person in the default mapping
xml = REXML::Document.new('
<person name="Suzy" age="28">
  <address>
    <street>Abbey Road</street>
    <number>72</number>
    <city>London</city>
    <zip>18827</zip>
  </address>
</person>').root

## load using the default mapping
p = Person.load_from_xml xml #<=

#:invisible_retval:
## save using the default mapping
xml2 = p.save_to_xml
xml2.write $stdout,2 #<=

## xml2 identical to xml


## now, save the same person to XML using the :other mapping...
other_xml = p.save_to_xml :mapping=>:other
other_xml.write $stdout,2 #<=

#:visible_retval:
## load it again using the :other mapping
p2 = Person.load_from_xml other_xml, :mapping=>:other #<=

#:invisible_retval:
## p2 identical to p #<=

#:invisible:
require 'test/unit/assertions'
include Test::Unit::Assertions

require 'xml/xxpath_methods'

assert_equal "Suzy", p.name
assert_equal 28, p.age
assert_equal "Abbey Road", p.address.street
assert_equal 72, p.address.number
assert_equal "London", p.address.city
assert_equal 18827, p.address.zip

assert_equal "individual", other_xml.name
assert_equal p.name, other_xml.first_xpath("name").text
assert_equal p.age, other_xml.first_xpath("age").text.to_i
assert_equal p.address.street, other_xml.first_xpath("street-name").text
assert_equal p.address.number, other_xml.first_xpath("street-name/@number").text.to_i
assert_equal p.address.city, other_xml.first_xpath("city-name").text
assert_equal p.address.zip, other_xml.first_xpath("city-name/@zip-code").text.to_i

#<=
