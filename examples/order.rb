require 'xml/mapping'

## forward declarations
class Client; end
class Address; end
class Item; end
class Signature; end


class Order
  include XML::Mapping

  text_node :reference, "@reference"
  object_node :client, "Client", :class=>Client
  hash_node :items, "Item", "@reference", :class=>Item
  array_node :signatures, "Signed-By", "Signature", :class=>Signature, :default_value=>[]

  def total_price
    items.values.map{|i| i.total_price}.inject(0){|x,y|x+y}
  end
end


class Client
  include XML::Mapping

  text_node :name, "Name"
  object_node :home_address, "Address[@where='home']", :class=>Address
  object_node :work_address, "Address[@where='work']", :class=>Address, :default_value=>nil
end


class Address
  include XML::Mapping

  text_node :city, "City"
  text_node :state, "State"
  numeric_node :zip, "ZIP"
  text_node :street, "Street"
end


class Item
  include XML::Mapping

  text_node :descr, "Description"
  numeric_node :quantity, "Quantity"
  numeric_node :unit_price, "UnitPrice"

  def total_price
    quantity*unit_price
  end
end


class Signature
  include XML::Mapping

  text_node :name, "Name"
  text_node :position, "Position", :default_value=>"Some Employee"
end
