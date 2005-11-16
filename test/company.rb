require 'xml/mapping'

# forward declarations
class Address; end
class Office; end
class Customer; end
class Thing; end


class Company
  include XML::Mapping

  text_node :name, "@name"

  object_node :address, "address", :class=>Address

  array_node :offices, "offices", "office", :class=>Office
  hash_node :customers, "customers", "customer", "@uid", :class=>Customer

  text_node :ent1, "arrtest/entry[1]"
  text_node :ent2, "arrtest/entry[2]"
  text_node :ent3, "arrtest/entry[3]"

  array_node :stuff, "stuff", "*"
  array_node :things, "stuff2", "thing", :class=>Thing
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
  # object_node :address, "address", :class=>Address
  object_node :address, "address",
        :marshaller=>proc {|xml,value| value.fill_into_xml(xml)},
        :unmarshaller=>proc {|xml| Address.load_from_xml(xml)}
end


class Customer
  include XML::Mapping

  text_node :uid, "@uid"
  text_node :name, "name"
end


class Thing
  include XML::Mapping

  choice_node 'name',  (text_node :name, 'name'),
              '@name', (text_node :name, '@name'),
              :else,   (text_node :name, '.')
end
