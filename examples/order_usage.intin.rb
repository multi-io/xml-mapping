#:invisible:
$:.unshift "../lib"
require 'order' #<=
#:visible:
o=Order.load_from_file("order.xml") #<=
o.reference #<=
o.client #<=
o.signatures #<=
o.items.keys #<=
o.items["RF-0034"].descr #<=
o.items["RF-0034"].total_price #<=
