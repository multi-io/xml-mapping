require 'rexml/document'
require "xml/xpath"

module XML

  # This is the central interface module of the xml-mapping library.
  #
  # Including this module in your classes adds XML mapping
  # capabilities to them.
  #
  # == Example
  #
  # === Input document:
  #
  #   <?xml version="1.0" encoding="ISO-8859-1"?>
  #
  #   <company name="ACME inc.">
  #
  #       <address>
  #         <city>Berlin</city>
  #         <zip>10113</zip>
  #       </address>
  #
  #       <customers>
  #
  #         <customer id="jim">
  #           <name>James Kirk</name>
  #         </customer>
  #
  #         <customer id="ernie">
  #           <name>Ernie</name>
  #         </customer>
  #
  #         <customer id="bert">
  #           <name>Bert</name>
  #         </customer>
  #
  #       </customers>
  #
  #   </company>
  #
  # === mapping class declaration:
  #
  #   require 'xml/mapping'
  #
  #   # forward declarations
  #   class Address; end
  #   class Customer; end
  #
  #
  #   class Company
  #     include XML::Mapping
  #
  #     text_node :name, "@name"
  #
  #     object_node :address, Address, "address"
  #
  #     array_node :customers, Customer, "customers", "customer"
  #   end
  #
  #
  #   class Address
  #     include XML::Mapping
  #
  #     text_node :city, "city"
  #     int_node :zip, "zip"
  #   end
  #
  #
  #   class Customer
  #     include XML::Mapping
  #
  #     text_node :id, "@id"
  #     text_node :name, "name"
  #
  #     def initialize(id,name)
  #       @id,@name = [id,name]
  #     end
  #   end
  #
  #
  # === usage:
  #
  #   irb(main)> c = Company.load_from_file('company.xml')
  #   => #<Company:0x40322ee0 @name="ACME inc.",
  #        @customers=[#<Customer:0x4031eda4 @name="James Kirk", @id="jim">,
  #                    #<Customer:0x4031c978 @name="Ernie", @id="ernie">,
  #                    #<Customer:0x40319d90 @name="Bert", @id="bert">],
  #        @address=#<Address:0x40322094 @zip=10113, @city="Berlin">>
  #   irb(main)>
  #   irb(main)* c.name
  #   => "ACME inc."
  #   irb(main)> c.customers.size
  #   => 3
  #   irb(main)> c.customers[1]
  #   => #<Customer:0x4031c978 @name="Ernie", @id="ernie">
  #   irb(main)> c.customers[1].name
  #   => "Ernie"
  #   irb(main)> c.customers[0].name
  #   => "James Kirk"
  #   irb(main)> c.customers[0].name = 'James Tiberius Kirk'
  #   => "James Tiberius Kirk"
  #   irb(main)* c.customers << Customer.new('cm','Cookie Monster')
  #   => [#<Customer:0x4031eda4 @name="James Tiberius Kirk", @id="jim">,
  #       #<Customer:0x4031c978 @name="Ernie", @id="ernie">,
  #       #<Customer:0x40319d90 @name="Bert", @id="bert">,
  #       #<Customer:0x4044fe30 @name="Cookie Monster", @id="cm">]
  #   irb(main)> xml2 = c.save_to_rexml
  #   => <company name='ACME inc.'> ... </>
  #   irb(main)> xml2.write(STDOUT,2)
  #   <company name='ACME inc.'>
  #         <address>
  #           <city>Berlin</city>
  #           <zip>10113</zip>
  #         </address>
  #         <customers>
  #           <customer id='jim'>
  #             <name>James Tiberius Kirk</name>
  #           </customer>
  #           <customer id='ernie'>
  #             <name>Ernie</name>
  #           </customer>
  #           <customer id='bert'>
  #             <name>Bert</name>
  #           </customer>
  #           <customer id='cm'>
  #             <name>Cookie Monster</name>
  #           </customer>
  #         </customers>
  #       </company>=> #<IO:0x402f4078>
  #   irb(main)>
  #
  # So, in addition to the class and instance methods described below,
  # you'll get one class methods like 'text_node', 'array_node' and so
  # on, that is, one class method for each registered /node
  # type/. Node types are classes deriving from XML::Mapping::Node;
  # they're registered via add_node_class.  Several node types
  # (TextNode, BooleanNode, IntNode, ObjectNode, ArrayNode, HashNode)
  # are automatically registered by xml/mapping.rb; you can easily
  # write your own ones.
  module Mapping

    def self.append_features(base)
      super
      base.extend(ClassMethods)
      base.xmlmapping_init
    end


    def fill_from_rexml(xml)
      pre_load(xml)
      self.class.xml_mapping_nodes.each do |node|
        node.xml_to_obj self, xml
      end
      post_load
    end

    def pre_load(xml)
    end

    def post_load
    end


    def fill_into_rexml(xml)
      self.class.xml_mapping_nodes.each do |node|
        node.obj_to_xml self,xml
      end
    end

    def save_to_rexml
      xml = pre_save
      fill_into_rexml(xml)
      post_save(xml)
      xml
    end

    def pre_save
      REXML::Element.new(self.class.root_element_name)
    end

    def post_save(xml)
    end


    def save_to_file(filename)
      xml = save_to_rexml
      File.open(filename,"w") do |f|
        xml.write(f,2)
      end
    end


    class Node
      def initialize(owner)
        @owner = owner
        owner.xml_mapping_nodes << self
      end
      def xml_to_obj(obj,xml)
        raise "abstract method called"
      end
      def obj_to_xml(obj,xml)
        raise "abstract method called"
      end
    end


    class SingleAttributeNode < Node
      def initialize(owner,attrname,*args)
        super(owner)
        @attrname = attrname
        owner.add_accessor attrname
        initialize_impl(*args)
      end
      def initialize_impl(*args)
        raise "abstract method called"
      end
      def xml_to_obj(obj,xml)
        obj.send :"#{@attrname}=", extract_attr_value(xml)
      end
      def extract_attr_value(xml)
        raise "abstract method called"
      end
      def obj_to_xml(obj,xml)
        set_attr_value(xml, obj.send(:"#{@attrname}"))
      end
      def set_attr_value(xml, value)
        raise "abstract method called"
      end
    end


    def self.add_node_class(c)
      meth_name = c.name.split('::')[-1].gsub(/^(.)/){$1.downcase}.gsub(/(.)([A-Z])/){$1+"_"+$2.downcase}
      ClassMethods.module_eval <<-EOS
        def #{meth_name}(attrname,*args)
          #{c.name}.new(self,attrname,*args)
        end
      EOS
    end


    module ClassMethods

      def add_accessor(name)
        name = name.id2name if name.kind_of? Symbol
        self.module_eval <<-EOS
          attr_accessor :#{name}
        EOS
      end

      def load_from_file(filename)
        xml = REXML::Document.new(File.new(filename))
        load_from_rexml(xml.root)
      end

      def load_from_rexml(xml)
        obj = self.new
        obj.fill_from_rexml(xml)
        obj
      end

      attr_accessor :xml_mapping_nodes

      def xmlmapping_init
        @xml_mapping_nodes = []
      end


      def root_element_name(name=nil)
        @root_element_name = name if name
        @root_element_name || default_root_element_name
      end

      def default_root_element_name
        self.name.split('::')[-1].gsub(/^(.)/){$1.downcase}.gsub(/(.)([A-Z])/){$1+"-"+$2.downcase}
      end

    end

  end

end
