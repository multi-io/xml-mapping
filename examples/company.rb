require 'xml/mapping'

## forward declarations
class Address; end
class Customer; end


class Company
  include XML::Mapping

  text_node :name, "@name"
  object_node :address, "address", :class=>Address
  array_node :customers, "customers", "customer", :class=>Customer
end


class Address
  include XML::Mapping

  text_node :city, "city"
  numeric_node :zip, "zip"
end


class Customer
  include XML::Mapping

  text_node :id, "@id"
  text_node :name, "name"

  def initialize(id,name)
    @id,@name = [id,name]
  end
end
