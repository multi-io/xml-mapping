#:invisible:
$:.unshift "../lib"
require 'order' #<=
#:visible:
class Time
  include XML::Mapping

  numeric_node :year, "year"
  numeric_node :month, "month"
  numeric_node :day, "mday"
  numeric_node :hour, "hours"
  numeric_node :min, "minutes"
  numeric_node :sec, "seconds"
end


nowxml=Time.now.save_to_xml #<=
#:invisible_retval:
nowxml.write($stdout,2)#<=
