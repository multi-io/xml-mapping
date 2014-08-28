# XML-MAPPING: XML-to-object (and back) Mapper for Ruby, including XPath Interpreter

Xml-mapping is an easy to use, extensible library that allows you to
semi-automatically map Ruby objects to XML trees and vice versa.


## Trivial Example

### sample document

    <?xml version="1.0" encoding="ISO-8859-1"?>

    <item reference="RF-0001">
        <Description>Stuffed Penguin</Description>
        <Quantity>10</Quantity>
        <UnitPrice>8.95</UnitPrice>
    </item>

### mapping class

    class Item
      include XML::Mapping

      text_node :ref, "@reference"
      text_node :descr, "Description"
      numeric_node :quantity, "Quantity"
      numeric_node :unit_price, "UnitPrice"

      def total_price
        quantity*unit_price
      end
    end


### usage

    i = Item.load_from_file("item.xml")
    => #<Item:0xb7888c90 @ref="RF-0001" @quantity=10, @descr="Stuffed Penguin", @unit_price=8.95>

    i.unit_price = 42.23
    xml=i.save_to_xml #convert to REXML node; there's also o.save_to_file(name)
    xml.write($stdout,2)

    <item reference="RF-0001">
        <Description>Stuffed Penguin</Description>
        <Quantity>10</Quantity>
        <UnitPrice>42.23</UnitPrice>
    </item>



This is the most trivial example -- the mapper supports arbitrary
array and hash (map) nodes, object (reference) nodes and arrays/hashes
of those, polymorphic mappings, multiple mapping per class, fully
programmable mappings and arbitrary user-defined node types. Read the
[project documentation](http://multi-io.github.io/xml-mapping/
"Project Page") for more information.
