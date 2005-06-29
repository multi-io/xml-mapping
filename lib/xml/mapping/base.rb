require 'rexml/document'
require "xml/xpath"

module XML

  class MappingError < RuntimeError
  end

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
  #   :include: company_usage.intout
  #
  # So you have to include XML::Mapping into your class to turn it
  # into a "mapping class", that is, to add XML mapping capabilities
  # to it. An instance of the mapping classes is then bidirectionally
  # mapped to an XML node (i.e. an element), where the state (simple
  # attributes, sub-objects, arrays, hashes etc.) of that instance is
  # mapped to sub-nodes of that node. In addition to the class and
  # instance methods defined in XML::Mapping, your mapping class will
  # get class methods like 'text_node', 'array_node' and so on; I call
  # them "node factory methods". More precisely, there is one node
  # factory method for each registered <em>node type</em>. Node types
  # are classes derived from XML::Mapping::Node; they're registered
  # with the xml-mapping library via XML::Mapping.add_node_class.  The
  # node types TextNode, BooleanNode, NumericNode, ObjectNode,
  # ArrayNode, and HashNode are automatically registered by
  # xml/mapping.rb; you can easily write your own ones. The name of a
  # node factory method is inferred by 'underscoring' the name of the
  # corresponding node type; e.g. 'TextNode' becomes 'text_node'. Each
  # node factory method creates an instance of the corresponding node
  # type and adds it to the mapping class (not its instances). The
  # arguments to a node factory method are automatically turned into
  # arguments to the corresponding node type's initializer. So, in
  # order to learn more about the meaning of a node factory method's
  # parameters, you read the documentation of the corresponding node
  # type. All predefined node types expect as their first argument a
  # symbol that names an r/w attribute which will be added to the
  # mapping class. The mapping class is a normal Ruby class; you can
  # add constructors, methods and attributes to it, derive from it,
  # derive it from another class, include additional modules etc.
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

    # can't really use class variables for these because they must be
    # shared by all class methods mixed into classes by including
    # Mapping. See
    # http://user.cs.tu-berlin.de/~klischat/mydocs/ruby/mixin_class_methods_global_state.txt.html
    # for a more detailed discussion.
    Classes_w_default_rootelt_names = {}     #:nodoc:
    Classes_w_nondefault_rootelt_names = {}  #:nodoc:

    def self.append_features(base) #:nodoc:
      super
      base.extend(ClassMethods)
      Classes_w_default_rootelt_names[base.default_root_element_name] = base
    end


    # Finds the mapping class corresponding to the given XML root
    # element name. This is the inverse operation to
    # <class>.root_element_name (see
    # XML::Mapping::ClassMethods.root_element_name).
    def self.class_for_root_elt_name(name)
      # TODO: implement Hash read-only instead of this
      # interface
      Classes_w_nondefault_rootelt_names[name] ||
        Classes_w_default_rootelt_names[name]
    end


    def initialize_xml_mapping  #:nodoc:
      self.class.all_xml_mapping_nodes.each do |node|
        node.obj_initializing(self)
      end
    end

    # private :initialize_xml_mapping

    # Initializer. Calls obj_initializing(self) on all nodes. You
    # should call this using +super+ in your mapping classes to
    # inherit this behaviour.
    def initialize(*args)
      initialize_xml_mapping
    end

    # "fill" the contents of _xml_ into _self_. _xml_ is a
    # REXML::Element.
    #
    # First, pre_load(_xml_) is called, then all the nodes for this
    # object's class are processed (i.e. have their
    # #xml_to_obj method called) in the order of their definition
    # inside the class, then #post_load is called.
    def fill_from_xml(xml)
      pre_load(xml)
      self.class.all_xml_mapping_nodes.each do |node|
        node.xml_to_obj self, xml
      end
      post_load
    end

    # This method is called immediately before _self_ is filled from
    # an xml source. _xml_ is the source REXML::Element.
    #
    # The default implementation of this method is empty.
    def pre_load(xml)
    end

    
    # This method is called immediately after _self_ has been filled
    # from an xml source. If you have things to do after the object
    # has been succefully loaded from the xml (reorganising the loaded
    # data in some way, setting up additional views on the data etc.),
    # this is the place where you put them. You can also raise an
    # exception to abandon the whole loading process.
    #
    # The default implementation of this method is empty.
    def post_load
    end


    # Fill _self_'s state into the xml node (REXML::Element)
    # _xml_. All the nodes for this object's class are processed
    # (i.e. have their
    # #obj_to_xml method called) in the order of their definition
    # inside the class.
    def fill_into_xml(xml)
      self.class.all_xml_mapping_nodes.each do |node|
        node.obj_to_xml self,xml
      end
    end

    # Fill _self_'s state into a new xml node, return that
    # node.
    #
    # This method calls #pre_save, then #fill_into_xml, then
    # #post_save.
    def save_to_xml
      xml = pre_save
      fill_into_xml(xml)
      post_save(xml)
      xml
    end

    # This method is called when _self_ is to be converted to an XML
    # tree. It *must* create and return an XML element (as a
    # REXML::Element); that element will then be passed to
    # #fill_into_xml.
    #
    # The default implementation of this method creates a new empty
    # element whose name is the #root_element_name of _self_'s class
    # (see ClassMethods.root_element_name). By default, this is the
    # class name, with capital letters converted to lowercase and
    # preceded by a dash, e.g. "MySampleClass" becomes
    # "my-sample-class".
    def pre_save
      REXML::Element.new(self.class.root_element_name)
    end

    # This method is called immediately after _self_'s state has been
    # filled into an XML element.
    #
    # The default implementation does nothing.
    def post_save(xml)
    end


    # Save _self_'s state as XML into the file named _filename_.
    # The XML is obtained by calling #save_to_xml.
    def save_to_file(filename)
      xml = save_to_xml
      File.open(filename,"w") do |f|
        xml.write(f,2)
      end
    end


    # Abstract base class for all node types. As mentioned in the
    # documentation for XML::Mapping, node types must be registered
    # using add_node_class, and a corresponding "node factory method"
    # (e.g. "text_node") will then be added as a class method to your
    # mapping classes. The node factory method is called from the body
    # of the mapping classes as demonstrated in the examples. It
    # creates an instance of its corresponding node type (the list of
    # parameters to the node factory method, preceded by the owning
    # mapping class, will be passed to the constructor of the node
    # type) and adds it to its owning mapping class, so there is one
    # node object per node definition per mapping class. That node
    # object will handle all XML marshalling/unmarshalling for this
    # node, for all instances of the mapping class. For this purpose,
    # the marshalling and unmarshalling methods of a mapping class
    # instance (fill_into_xml and fill_from_xml, respectively)
    # will call obj_to_xml resp. xml_to_obj on all nodes of the
    # mapping class, in the order of their definition, passing the
    # REXML element the data is to be marshalled to/unmarshalled from
    # as well as the object the data is to be read from/filled into.
    #
    # Node types that map some XML data to a single attribute of their
    # mapping class (that should be most of them) shouldn't be
    # directly derived from this class, but rather from
    # SingleAttributeNode.
    class Node
      # Intializer, to be called from descendant classes. _owner_ is
      # the mapping class this node is being defined in. It'll be
      # stored in _@owner_.
      def initialize(owner)
        @owner = owner
        owner.xml_mapping_nodes << self
      end
      # This is called by the XML unmarshalling machinery when the
      # state of an instance of this node's @owner is to be read from
      # an XML node. _obj_ is the instance, _xml_ is the element (a
      # REXML::Element). The node must read "its" data from _xml_
      # (using XML::XPath or any other means) and store it to the
      # corresponding parts (attributes etc.) of _obj_'s state.
      def xml_to_obj(obj,xml)
        raise "abstract method called"
      end
      # This is called by the XML unmarshalling machinery when the
      # state of an instance of this node's @owner is to be stored
      # into an XML node. _obj_ is the instance, _xml_ is the element
      # (a REXML::Element). The node must extract "its" data from
      # _obj_ and store it to the corresponding parts (sub-elements,
      # attributes etc.) of _xml_ (using XML::XPath or any other
      # means).
      def obj_to_xml(obj,xml)
        raise "abstract method called"
      end
      # Called when a new instance is being initialized. _obj_ is the
      # instance. You may set up initial values for the attributes
      # this node is responsible for here. Default implementation is
      # empty.
      def obj_initializing(obj)
      end
    end


    # Base class for node types that map some XML data to a single
    # attribute of their mapping class. This class also introduces a
    # general "options" hash parameter which may be used to influence
    # the creation of nodes in numerous ways, e.g. by providing
    # default attribute values when there is no source data in the
    # mapped XML.
    #
    # All node types that come with xml-mapping inherit from
    # SingleAttributeNode.
    class SingleAttributeNode < Node
      # Initializer. _owner_ is the owning mapping class (gets passed
      # to the superclass initializer and therefore put into
      # @owner). The second parameter (and hence the first parameter
      # to the node factory method), _attrname_, is a symbol that
      # names the mapping class attribute this node should map to. It
      # gets stored into @attrname, and the attribute (an r/w
      # attribute of name attrname) is added to the mapping class
      # (using attr_accessor).
      #
      # If the last argument is a hash, it is assumed to be the
      # abovementioned "options hash", and is stored into
      # @options. Two entries -- :optional and :default_value -- in
      # the options hash are already processed in SingleAttributeNode:
      #
      # Supplying :default_value=>_obj_ makes _obj_ the _default
      # value_ for this attribute. When unmarshalling (loading) an
      # object from an XML source, the attribute will be set to this
      # value if nothing was provided in the XML; when marshalling
      # (saving), the attribute won't be saved if it is set to the
      # default value.
      #
      # Providing just :optional=>true is equivalent to providing
      # :default_value=>nil.
      #
      # The remaining arguments are passed to initialize_impl, which
      # is the initializer subclasses should overwrite instead of
      # initialize.
      #
      # For example (TextNode is a subclass of SingleAttributeNote):
      #
      #   class Address
      #     include XML::Mapping
      #     text_node :city, "city", :optional=>true, :default_value=>"Berlin"
      #   end
      #
      # Here +Address+ is the _owner_, <tt>:city</tt> is the
      # _attrname_,
      # <tt>{:optional=>true,:default_value=>"Berlin"}</tt> is the
      # @options, and ["city"] is the argument list that'll be passed
      # to TextNode.initialize_impl. "city" is of course the XPath
      # expression locating the XML sub-element this text node refers
      # to; TextNode.initialize_impl stores it into @path.
      def initialize(owner,attrname,*args)
        super(owner)
        @attrname = attrname
        owner.add_accessor attrname
        if Hash===args[-1]
          @options = args[-1]
          args = args[0..-2]
        else
          @options={}
        end
        if @options[:optional] and not(@options.has_key?(:default_value))
          @options[:default_value] = nil
        end
        initialize_impl(*args)
      end
      # Initializer to be implemented by subclasses.
      def initialize_impl(*args)
        raise "abstract method called"
      end

      # Exception that may be used by implementations of
      # #extract_attr_value to announce that the attribute value is
      # not set in the XML and, consequently, the default value should
      # be set in the object being created, or an Exception be raised
      # if no default value was specified.
      class NoAttrValueSet < XPathError
      end

      def xml_to_obj(obj,xml)  # :nodoc:
        begin
          obj.send :"#{@attrname}=", extract_attr_value(xml)
        rescue NoAttrValueSet => err
          unless @options.has_key? :default_value
            raise XML::MappingError, "no value, and no default value: #{err}"
          end
          obj.send :"#{@attrname}=", @options[:default_value]
        end
      end

      # (to be overridden by subclasses) Extract and return the
      # attribute's value from _xml_. In the example above, TextNode's
      # implementation would return the current value of the
      # sub-element named by @path (i.e., "city"). If the
      # implementation decides that the attribute value is "unset" in
      # _xml_, it should raise NoAttrValueSet in order to initiate
      # proper handling of possibly supplied :optional and
      # :default_value options (you may use #default_when_xpath_err
      # for this purpose).
      def extract_attr_value(xml)
        raise "abstract method called"
      end
      def obj_to_xml(obj,xml) # :nodoc:
        value = obj.send(:"#{@attrname}")
        if @options.has_key? :default_value
          unless value == @options[:default_value]
            set_attr_value(xml, value)
          end
        else
          if value == nil
            raise XML::MappingError, "no value, and no default value, for attribute #{@attrname}"
          end
          set_attr_value(xml, value)
        end
      end
      # (to be overridden by subclasses) Write _value_ into the
      # correct sub-nodes of _xml_.
      def set_attr_value(xml, value)
        raise "abstract method called"
      end
      def obj_initializing(obj)  # :nodoc:
        if @options.has_key? :default_value
          obj.send :"#{@attrname}=", @options[:default_value]
        end
      end
      # utility method to be used by implementations of
      # #extract_attr_value. Calls the supplied block, catching
      # XML::XPathError and mapping it to NoAttrValueSet. This is for
      # the common case that an implementation considers an attribute
      # value not to be present in the XML if some specific sub-path
      # does not exist.
      def default_when_xpath_err # :yields:
        begin
          yield
        rescue XML::XPathError => err
          raise NoAttrValueSet, "Attribute #{@attrname} not set (XPathError: #{err})"
        end
      end
    end


    # Registers the new node class _c_ (must be a descendant of Node)
    # with the xml-mapping framework.
    #
    # A new "factory method" will automatically be added to
    # ClassMethods (and therefore to all classes that include
    # XML::Mapping from now on); so you can call it from the body of
    # your mapping class definition in order to create nodes of type
    # _c_. The name of the factory method is derived by "underscoring"
    # the (unqualified) name of _c_;
    # e.g. _c_==<tt>Foo::Bar::MyNiftyNode</tt> will result in the
    # creation of a factory method named +my_nifty_node+. The
    # generated factory method creates and returns a new instance of
    # _c_. The list of argument to _c_.new consists of _self_
    # (i.e. the mapping class the factory method was called from)
    # followed by the arguments passed to the factory method. You
    # should always use the factory methods to create instances of
    # node classes; you should never need to call a node class's
    # constructor directly.
    #
    # For a demonstration, see the calls to +text_node+, +array_node+
    # etc. in the examples along with the corresponding node classes
    # TextNode, ArrayNode etc. (these predefined node classes are in
    # no way "special"; they're added using add_node_class in
    # mapping.rb just like any custom node classes would be).
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
    #ClassMethods = Module.new do  # this is the alterbative -- but see above for peculiarities

      # Add getter and setter methods for a new attribute named _name_
      # to this class. This is a convenience method intended to be
      # called from Node class initializers.
      def add_accessor(name)
        name = name.id2name if name.kind_of? Symbol
        unless self.instance_methods.include?(name)
          self.module_eval <<-EOS
            attr_reader :#{name}
          EOS
        end
        unless self.instance_methods.include?("#{name}=")
          self.module_eval <<-EOS
            attr_writer :#{name}
          EOS
        end
      end

      # Create a new instance of this class from the XML contained in
      # the file named _filename_. Calls load_from_xml internally.
      def load_from_file(filename)
        xml = REXML::Document.new(File.new(filename))
        load_from_xml(xml.root)
      end

      # Create a new instance of this class from the XML contained in
      # _xml_ (a REXML::Element).
      #
      # Allocates a new object, then calls fill_from_xml(_xml_) on
      # it.
      def load_from_xml(xml)
        obj = self.allocate
        obj.initialize_xml_mapping
        obj.fill_from_xml(xml)
        obj
      end


      # array of all nodes types defined in this class, in the order
      # of their definition
      def xml_mapping_nodes
        @xml_mapping_nodes ||= []
      end


      # enumeration of all nodes types in effect when
      # marshalling/unmarshalling this class, that is, node types
      # defined for this class as well as for its superclasses.  The
      # node types are returned in the order of their definition,
      # starting with the topmost superclass that has node types
      # defined.
      def all_xml_mapping_nodes
        # TODO: we could return a dynamic Enumerable here, or cache
        # the array...
        result = []
        if superclass and superclass.respond_to?(:all_xml_mapping_nodes)
          result += superclass.all_xml_mapping_nodes
        end
        result += xml_mapping_nodes
      end


      # The "root element name" of this class (combined getter/setter
      # method).
      #
      # The root element name is the name of the root element of the
      # XML tree returned by <this class>.#save_to_xml (or, more
      # specifically, <this class>.#pre_save). By default, this method
      # returns the #default_root_element_name; you may call this
      # method with an argument to set the root element name to
      # something other than the default.
      def root_element_name(name=nil)
        if name
          Classes_w_nondefault_rootelt_names.delete(root_element_name)
          Classes_w_default_rootelt_names.delete(root_element_name)
          Classes_w_default_rootelt_names.delete(name)

          @root_element_name = name

          Classes_w_nondefault_rootelt_names[name]=self
        end
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



    # "polymorphic" load function. Turns the XML tree _xml_ into an
    # object, which is returned. The class of the object is
    # automatically determined from the root element name of _xml_
    # using XML::Mapping::class_for_root_elt_name.
    def self.load_object_from_xml(xml)
      unless c = class_for_root_elt_name(xml.name)
        raise MappingError, "no mapping class for root element name #{xml.name}"
      end
      c.load_from_xml(xml)
    end

    # Like load_object_from_xml, but loads from the XML file named by
    # _filename_.
    def self.load_object_from_file(filename)
      xml = REXML::Document.new(File.new(filename))
      load_object_from_xml(xml.root)
    end

  end

end
