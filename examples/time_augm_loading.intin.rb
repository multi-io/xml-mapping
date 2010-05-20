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
    [xml.first_xpath("year").text.to_i,
     xml.first_xpath("month").text.to_i,
     xml.first_xpath("mday").text.to_i,
     xml.first_xpath("hours").text.to_i,
     xml.first_xpath("minutes").text.to_i,
     xml.first_xpath("seconds").text.to_i]
  Time.local(year,month,day,hour,min,sec)
end
#<=
#:invisible:
require 'test/unit/assertions'
include Test::Unit::Assertions

t = Time.now
t2 = Time.load_from_xml(t.save_to_xml)

assert_equal t.year, t2.year
assert_equal t.month, t2.month
assert_equal t.day, t2.day
assert_equal t.hour, t2.hour
assert_equal t.min, t2.min
assert_equal t.sec, t2.sec
