require 'xml/mapping'
class People
  include XML::Mapping
  array_node :names, "names", "name", :class=>String
end
