#:invisible:
$:.unshift "../lib"
require 'xml/mapping'
require 'xml/xxpath_methods'

class Time
  include XML::Mapping

  numeric_node :year, "year"
  numeric_node :month, "month"
  numeric_node :day, "mday"
  numeric_node :hour, "hours"
  numeric_node :min, "minutes"
  numeric_node :sec, "seconds"
end

#<=
#:invisible_retval:
#:visible:

def Time.load_from_xml(xml, options={:mapping=>:_default})
  year,month,day,hour,min,sec =
    [xml.first("year").text.to_i,
     xml.first("month").text.to_i,
     xml.first("mday").text.to_i,
     xml.first("hours").text.to_i,
     xml.first("minutes").text.to_i,
     xml.first("seconds").text.to_i]
  Time.local(year,month,day,hour,min,sec)
end
#<=
#:invisible:
require 'test/unit/assertions'
include Test::Unit::Assertions

t = Time.now
nowxml = t.save_to_xml

assert_equal t.year, nowxml.first("year").text.to_i
assert_equal t.month, nowxml.first("month").text.to_i
assert_equal t.day, nowxml.first("mday").text.to_i
assert_equal t.hour, nowxml.first("hours").text.to_i
assert_equal t.min, nowxml.first("minutes").text.to_i
assert_equal t.sec, nowxml.first("seconds").text.to_i
