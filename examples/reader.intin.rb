#:invisible:
$:.unshift "../lib"
require 'xml/mapping'
require 'xml/xxpath_methods'
#<=
#:visible:

class Foo
  include XML::Mapping

  text_node :name, "@name", :reader=>proc{|obj,xml,default_reader|
                                       default_reader.call(obj,xml)
                                       obj.name += xml.attributes['more']
                                     },
                            :writer=>proc{|obj,xml|
                                       xml.attributes['bar'] = "hi #{obj.name} ho"
                                     }
end

f = Foo.load_from_xml(REXML::Document.new('<foo name="Jim" more="XYZ"/>').root)#<=

#:invisible_retval:
xml = f.save_to_xml 
xml.write $stdout,2 #<=

#:invisible:
require 'test/unit/assertions'
include Test::Unit::Assertions

assert_equal "JimXYZ", f.name
assert_equal "hi JimXYZ ho", xml.attributes['bar']

#<=
