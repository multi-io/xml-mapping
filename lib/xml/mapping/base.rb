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
  #   :include: company.xml
  #
  # === mapping class declaration:
  #
  #   :include: company.rb
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
  # So, you have to include XML::Mapping into your class to turn it
  # into a mapping class, that is, to add XML mappings to it. In
  # addition to the class and instance methods defined in
  # XML::Mapping, your mapping class will get class methods like
  # 'text_node', 'array_node' and so on; I call them "node factory
  # methods". More precisely, there is one node factory method for
  # each registered <em>node type</em>. Node types are classes derived
  # from XML::Mapping::Node; they're registered via
  # #add_node_class.  The node types TextNode, BooleanNode, IntNode,
  # ObjectNode, ArrayNode, and HashNode are automatically registered
  # by xml/mapping.rb; you can easily write your own ones. The name of
  # a node factory method is inferred by 'underscoring' the name of
  # the corresponding node type; e.g. 'TextNode' becomes
  # 'text_node'. The arguments to a node factory method are
  # automatically turned into arguments to the corresponding node
  # type's initializer. So, in order to learn more about the meaning
  # of a node factory method's parameters, you read the documentation
  # of the corresponding node type. All predefined node types expect
  # as their first argument a symbol that names an r/w attribute which
  # will be added to the mapping class. The mapping class is a normal
  # Ruby class; you can add constructors, methods and attributes to
  # it, derive from it, derive it from another class, include
  # additional modules etc.
  #
  # Including XML::Mapping also adds all methods of
  # XML::Mapping::ClassMethods to your class (as class methods).
  #
  # As you may have noticed from the example, the node factory methods
  # generally use XPath expressions to specify locations in the mapped
  # XML document. To make this work, XML::Mapping relies on
  # XML::XPath, which implements a subset of XPath, but also provides
  # write access, which is needed by the node types to support writing
  # data back to XML. Both XML::Mapping and XML::XPath use REXML
  # (http://www.germane-software.com/software/rexml/) to represent XML
  # elements/documents in memory.
  module Mapping

    def self.append_features(base) #:nodoc:
      super
      base.extend(ClassMethods)
      base.xmlmapping_init
    end


    # "fill" the contents of _xml_ into _self_. _xml_ is a
    # REXML::Element or REXML::Document.
    #
    # First, pre_load(_xml_) is called, then all the nodes for this
    # object's class are processed (i.e. have their
    # #xml_to_obj method called) in the order of their definition
    # inside the class, then #post_load is called.
    def fill_from_rexml(xml)
      pre_load(xml)
      self.class.xml_mapping_nodes.each do |node|
        node.xml_to_obj self, xml
      end
      post_load
    end

    # This method is called immediately before _self_ is filled
    # from an xml source. _xml_ is the source REXML::Element or
    # REXML::Document.
    #
    # The default implementation of this method is empty.
    def pre_load(xml)
    end

    
    # This method is called immediately after _self_ has been
    # filled from an xml source. You may set up additional field
    # values here, for example.
    #
    # The default implementation of this method is empty.
    def post_load
    end


    # Fill _self_'s state into the xml node (REXML::Element or
    # REXML::Document) _xml_. All the nodes for this
    # object's class are processed (i.e. have their
    # #obj_to_xml method called) in the order of their definition
    # inside the class.
    def fill_into_rexml(xml)
      self.class.xml_mapping_nodes.each do |node|
        node.obj_to_xml self,xml
      end
    end

    # Fill _self_'s state into a new xml node, return that
    # node.
    #
    # This method calls #pre_save, then #fill_into_rexml, then
    # #post_save.
    def save_to_rexml
      xml = pre_save
      fill_into_rexml(xml)
      post_save(xml)
      xml
    end

    # This method is called immediately before _self_'s state is
    # filled into an XML element. It *must* return a new
    # REXML::Element, which will then be passed to #fill_into_rexml.
    #
    # The default implementation of this method creates a new
    # REXML::Element whose name will be the #root_element_name of
    # _self_'s class. By default, this is the class name, with capital
    # letters converted to lowercase and preceded by a dash,
    # e.g. "MySampleClass" becomes "my-sample-class".
    def pre_save
      REXML::Element.new(self.class.root_element_name)
    end

    # This method is called immediately after _self_'s state has been
    # filled into an XML element.
    #
    # The default implementation does nothing.
    def post_save(xml)
    end


    # Save _self_'s state (generated by calling #save_to_rexml) as XML
    # into the file named _filename_.
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


    # Registers the new node class _c_ (must be a descendant of Node)
    # with the xml-mapping framework.
    #
    # A new "factory method" will be automatically added to
    # ClassMethods (and therefore to all classes that include
    # XML::Mapping from now on); so you can call it from the body of
    # your mapping class definition in order to create nodes of type
    # _c_. The name of the factory method is derived by "underscoring"
    # the (unqualified) name of _c_; e.g. _c_==+Foo::Bar::MyNiftyNode+
    # will result in the creation of a factory method named
    # +my_nifty_node+. The generated factory method creates and
    # returns a new instance of _c_. The list of argument to _c_.new
    # consists of _self_ (i.e. this class) followed by the arguments
    # passed to the factory method. You should always use the factory
    # methods to create instances of node classes; you should never
    # need to call a node class's constructor directly.
    #
    # For a demonstration, see the calls to +text_node+, +array_node+
    # etc. in the examples along with the corresponding node classes
    # TextNode, ArrayNode etc. (these predefined node classes are in
    # no way "special"; they're added using add_node_class in
    # mapping.rb just like any custom node classes would be.
    def self.add_node_class(c)
      meth_name = c.name.split('::')[-1].gsub(/^(.)/){$1.downcase}.gsub(/(.)([A-Z])/){$1+"_"+$2.downcase}
      ClassMethods.module_eval <<-EOS
        def #{meth_name}(*args)
          #{c.name}.new(self,*args)
        end
      EOS
    end


    # The instance methods of this module are automatically added as
    # class methods to a class that includes XML::Mapping.
    module ClassMethods

      # Add getter and setter methods for a new attribute named _name_
      # (a string) to this class. This is a convenience method
      # intended to be called from Node class initializers.
      def add_accessor(name)
        name = name.id2name if name.kind_of? Symbol
        self.module_eval <<-EOS
          attr_accessor :#{name}
        EOS
      end

      # Create a new instance of this class from the XML contained in
      # the file named _filename_. Calls load_from_rexml internally.
      def load_from_file(filename)
        xml = REXML::Document.new(File.new(filename))
        load_from_rexml(xml.root)
      end

      # Create a new instance of this class from the XML contained in
      # _xml_ (a REXML::Element or REXML::Document).
      #
      # Allocates a new object, then calls fill_from_rexml(_xml_) on
      # it.
      def load_from_rexml(xml)
        obj = self.allocate
        obj.fill_from_rexml(xml)
        obj
      end

      attr_accessor :xml_mapping_nodes

      def xmlmapping_init  #:nodoc:
        @xml_mapping_nodes = []
      end


      # The "root element name" of this class (combined getter/setter
      # method).
      #
      # The root element name is the name of the root element of the
      # XML tree returned by <this class>.#save_to_rexml (or, more
      # specifically, <this class>.#pre_save). By default, this method
      # returns the #default_root_element_name; you may call this
      # method with an argument to set the root element name to
      # something other than the default.
      def root_element_name(name=nil)
        @root_element_name = name if name
        @root_element_name || default_root_element_name
      end


      # The default root element name for this class. Equals the class
      # name, with all parent module names stripped, and with capital
      # letters converted to lowercase and preceded by a dash;
      # e.g. "Foo::Bar::MySampleClass" becomes "my-sample-class".
      def default_root_element_name
        self.name.split('::')[-1].gsub(/^(.)/){$1.downcase}.gsub(/(.)([A-Z])/){$1+"-"+$2.downcase}
      end

    end

  end

end
