#:invisible:
$:.unshift "../lib"
require 'xml/mapping'
require 'time_node.rb'
require 'order'
require 'order_signature_enhanced'
#<=
#:visible:
s=Signature.load_from_file("order_signature_enhanced.xml") #<=
s.signed_on #<=
s.signed_on=Time.local(1976,12,18) #<=
s.save_to_xml.write($stdout,2) #<=
