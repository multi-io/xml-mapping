require 'xml/mapping'

# forward declarations
class Address; end
class Office; end
class Customer; end


class Company
  include XML::Mapping

  text_node :name, "@name"

  object_node :address, "address", :class=>Address

  array_node :offices, "offices", "office", :class=>Office
  hash_node :customers, "customers", "customer", "@id", :class=>Customer

  text_node :ent1, "arrtest/entry[1]"
  text_node :ent2, "arrtest/entry[2]"
  text_node :ent3, "arrtest/entry[3]"
end


class Address
  include XML::Mapping

  text_node :city, "city"
  numeric_node :zip, "zip", :default_value=>12576
  text_node :street, "street", :optional=>true
  numeric_node :number, "number"
end


class Office
  include XML::Mapping

  text_node :speciality, "@speciality"
  boolean_node :classified, "classified", "yes", "no"
  object_node :address, "address", :class=>Address
end


class Customer
  include XML::Mapping

  text_node :id, "@id"
  text_node :name, "name"
end
