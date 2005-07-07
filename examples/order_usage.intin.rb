#:invisible:
$:.unshift "../lib"
begin
  Object.send(:remove_const, "Address")  # name clash with company_usage...
rescue
end
require 'order' #<=
#:visible:
####read access
o=Order.load_from_file("order.xml") #<=
o.reference #<=
o.client #<=
o.items.keys #<=
o.items["RF-0034"].descr #<=
o.items["RF-0034"].total_price #<=
o.signatures #<=
o.signatures[2].name #<=
o.signatures[2].position #<=
## default value was set

o.total_price #<=

####write access
o.client.name="James T. Kirk"
o.items['RF-4711'] = Item.new
o.items['RF-4711'].descr = 'power transfer grid'
o.items['RF-4711'].quantity = 2
o.items['RF-4711'].unit_price = 29.95

s=Signature.new
s.name='Harry Smith'
s.position='general manager'
o.signatures << s
xml=o.save_to_xml #convert to REXML node; there's also o.save_to_file(name) #<=
#:invisible_retval:
xml.write($stdout,2) #<=
#:visible_retval:

####Starting a new order from scratch
o = Order.new #<=
## attributes with default values (here: signatures) are set
## automatically

#:handle_exceptions:
xml=o.save_to_xml #<=
#:no_exceptions:
## can't save as long as there are still unset attributes without
## default values

o.reference = "FOOBAR-1234"

o.client = Client.new
o.client.name = 'Ford Prefect'
o.client.home_address = Address.new
o.client.home_address.street = '42 Park Av.'
o.client.home_address.city = 'small planet'
o.client.home_address.zip = 17263
o.client.home_address.state = 'Betelgeuse system'

o.items={'XY-42' => Item.new}
o.items['XY-42'].descr = 'improbability drive'
o.items['XY-42'].quantity = 3
o.items['XY-42'].unit_price = 299.95

#:invisible_retval:
o.save_to_xml.write($stdout,2)
#<=
#:visible_retval:

## the root element name when saving an object to XML will by default
## be derived from the class name (in this example, "Order" became
## "order"). This can be overridden on a per-class basis; see
## XML::Mapping::ClassMethods#root_element_namefor details.
