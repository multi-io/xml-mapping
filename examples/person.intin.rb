#:invisible:
$:.unshift "../lib"
require 'xml/mapping'
require 'xml/xxpath_methods'
#<=
#:visible:

class Person
  include XML::Mapping

  choice_node :if,    'name',  :then, (text_node :name, 'name'),
              :elsif, '@name', :then, (text_node :name, '@name'),
              :else,  (text_node :name, '.')
end

p1 = Person.load_from_xml(REXML::Document.new('<person name="Jim"/>').root)#<=

p2 = Person.load_from_xml(REXML::Document.new('<person><name>James</name></person>').root)#<=

p3 = Person.load_from_xml(REXML::Document.new('<person>Suzy</person>').root)#<=


#:invisible_retval:

p1.save_to_xml.write($stdout)#<=

p2.save_to_xml.write($stdout)#<=

p3.save_to_xml.write($stdout)#<=

#:invisible:
assert_equal "Jim", p1.name
assert_equal "James", p2.name
assert_equal "Suzy", p3.name

xml = p3.save_to_xml
assert_equal "name", xml.elements[1].name
assert_equal "Suzy", xml.elements[1].text

#<=
