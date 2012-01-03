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

  object_node :test_default_value_identity, "dummy", :default_value => ["default"]
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


class Names1
  include XML::Mapping

  choice_node :if,    'name',       :then, (text_node :name, 'name'),
              :elsif, 'names/name', :then, (array_node :names, 'names', 'name', :class=>String)
end


class ReaderTest
  include XML::Mapping

  attr_accessor :read

  text_node :foo, "foo"
  text_node :foo2, "foo2", :reader=>proc{|obj,xml| (obj.read||=[]) << :foo2 }
  text_node :foo3, "foo3", :reader=>proc{|obj,xml,default|
                                            (obj.read||=[]) << :foo3
                                            default.call(obj,xml)
                                        }
  text_node :bar, "bar"
end


class WriterTest
  include XML::Mapping

  text_node :foo, "foo"
  text_node :foo2, "foo2", :writer=>proc{|obj,xml| e = xml.elements.add; e.name='quux'; e.text='dingdong2' }
  text_node :foo3, "foo3", :writer=>proc{|obj,xml,default|
                                            default.call(obj,xml)
                                            e = xml.elements.add; e.name='quux'; e.text='dingdong3'
                                        }
  text_node :bar, "bar"
end


class ReaderWriterProcVsLambdaTest
  include XML::Mapping

  attr_accessor :read, :written

  text_node :proc_2args, "proc_2args", :reader=>Proc.new{|obj,xml|
                                                            (obj.read||=[]) << :proc_2args
                                                        },
                                       :writer=>Proc.new{|obj,xml|
                                                            (obj.written||=[]) << :proc_2args
                                                        }

  text_node :proc_3args, "proc_3args", :reader=>Proc.new{|obj,xml,default|
                                                            (obj.read||=[]) << :proc_3args
                                                            default.call(obj,xml)
                                                        },
                                       :writer=>Proc.new{|obj,xml,default|
                                                            (obj.written||=[]) << :proc_3args
                                                            default.call(obj,xml)
                                                        }


  text_node :lambda_2args, "lambda_2args", :reader=>lambda{|obj,xml|
                                                              (obj.read||=[]) << :lambda_2args
                                                          },
                                           :writer=>lambda{|obj,xml|
                                                              (obj.written||=[]) << :lambda_2args
                                                          }


  text_node :lambda_3args, "lambda_3args", :reader=>lambda{|obj,xml,default|
                                                              (obj.read||=[]) << :lambda_3args
                                                              default.call(obj,xml)
                                                          },
                                           :writer=>lambda{|obj,xml,default|
                                                              (obj.written||=[]) << :lambda_3args
                                                              default.call(obj,xml)
                                                          }


end
