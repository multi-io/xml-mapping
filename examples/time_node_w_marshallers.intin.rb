#:invisible:
#:invisible_retval:
$:.unshift "../lib" #<=
#:visible:
require 'xml/mapping'
require 'xml/xxpath_methods'

class Signature
  include XML::Mapping

  text_node :name, "Name"
  text_node :position, "Position", :default_value=>"Some Employee"
  object_node :signed_on, "signed-on",
              :unmarshaller=>proc{|xml|
                               y,m,d = [xml.first_xpath("year").text.to_i,
                                        xml.first_xpath("month").text.to_i,
                                        xml.first_xpath("day").text.to_i]
                               Time.local(y,m,d)
                             },
              :marshaller=>proc{|xml,value|
                             e = xml.elements.add; e.name = "year"; e.text = value.year
                             e = xml.elements.add; e.name = "month"; e.text = value.month
                             e = xml.elements.add; e.name = "day"; e.text = value.day

                             # xml.first("year",:ensure_created=>true).text = value.year
                             # xml.first("month",:ensure_created=>true).text = value.month
                             # xml.first("day",:ensure_created=>true).text = value.day
                           }
end #<=
#:invisible:
require 'test/unit/assertions'

include Test::Unit::Assertions

t=Time.local(2005,12,1)

s=Signature.new
s.name = "Olaf Klischat"; s.position="chief"; s.signed_on=t
xml = s.save_to_xml

assert_equal "2005", xml.first_xpath("signed-on/year").text
assert_equal "12", xml.first_xpath("signed-on/month").text
assert_equal "1", xml.first_xpath("signed-on/day").text

s2 = Signature.load_from_xml xml
assert_equal "Olaf Klischat", s2.name
assert_equal "chief", s2.position
assert_equal t, s2.signed_on
