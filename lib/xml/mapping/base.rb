# xml-mapping -- bidirectional Ruby-XML mapper
#  Copyright (C) 2004-2006 Olaf Klischat

require 'rexml/document'
require "xml/xxpath"

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
  # It is recommended that if your class does not have required
  # +initialize+ method arguments. The XML loader attempts to create a
  # new object using the +new+ method. If this fails because the
  # initializer expects an argument, then the loader calls +allocate+
  # instead. +allocate+ bypasses the initializer.  If your class must
  # have initializer arguments, then you should verify that bypassing
  # the initializer is acceptable.
  #
  # As you may have noticed from the example, the node factory methods
  # generally use XPath expressions to specify locations in the mapped
  # XML document. To make this work, XML::Mapping relies on
  # XML::XXPath, which implements a subset of XPath, but also provides
  # write access, which is needed by the node types to support writing
  # data back to XML. Both XML::Mapping and XML::XXPath use REXML
  # (http://www.germane-software.com/software/rexml/) to represent XML
  # elements/documents in memory.
  module Mapping

    # defined mapping classes for a given root elt name and mapping
    # name (nested map from root element name to mapping name to array
    # of classes)
    #
    # can't really use a class variable for this because it must be
    # shared by all class methods mixed into classes by including
    # Mapping. See
    # http://user.cs.tu-berlin.de/~klischat/mydocs/ruby/mixin_class_methods_global_state.txt.html
    # for a more detailed discussion.
    Classes_by_rootelt_names = {}  #:nodoc:
    class << Classes_by_rootelt_names
      def create_classes_for rootelt_name, mapping
        (self[rootelt_name] ||= {})[mapping] ||= []
      end
      def classes_for rootelt_name, mapping
        (self[rootelt_name] || {})[mapping] || []
      end
      def remove_class rootelt_name, mapping, clazz
        classes_for(rootelt_name, mapping).delete clazz
      end
      def ensure_exists rootelt_name, mapping, clazz
        clazzes = create_classes_for(rootelt_name, mapping)
        clazzes << clazz unless clazzes.include? clazz
      end
    end


    def self.append_features(base) #:nodoc:
      super
      base.extend(ClassMethods)
      Classes_by_rootelt_names.create_classes_for(base.default_root_element_name, :_default) << base
      base.initializing_xml_mapping
    end

    # Finds a mapping class corresponding to the given XML root
    # element name and mapping name. There may be more than one such class --
    # in that case, the most recently defined one is returned
    #
    # This is the inverse operation to
    # <class>.root_element_name (see
    # XML::Mapping::ClassMethods.root_element_name).
    def self.class_for_root_elt_name(name, options={:mapping=>:_default})
      # TODO: implement Hash read-only instead of this
      # interface
      Classes_by_rootelt_names.classes_for(name, options[:mapping])[-1]
    end

    # Finds a mapping class and mapping name corresponding to the
    # given XML root element name. There may be more than one
    # (class,mapping) tuple for a given root element name -- in that
    # case, one of them is selected arbitrarily.
    #
    # returns [class,mapping]
    def self.class_and_mapping_for_root_elt_name(name)
      (Classes_by_rootelt_names[name] || {}).each_pair{|mapping,classes| return [classes[0],mapping] }
      nil
    end

    # Xml-mapping-specific initializer.
    #
    # This will be called when a new instance is being initialized
    # from an XML source, as well as after calling _class_._new_(args)
    # (for the latter case to work, you'll have to make sure you call
    # the inherited _initialize_ method)
    #
    # The :mapping keyword argument gives the mapping the instance is
    # being initialized with. This is non-nil only when the instance
    # is being initialized from an XML source (:mapping will contain
    # the :mapping argument passed (explicitly or implicitly) to the
    # load_from_... method).
    #
    # When the instance is being initialized because _class_._new_ was
    # called, the :mapping argument is set to nil to show that the
    # object is being initialized with respect to no specific mapping.
    #
    # The default implementation of this method calls obj_initializing
    # on all nodes. You may overwrite this method to do your own
    # initialization stuff; make sure to call +super+ in that case.
    def initialize_xml_mapping(options={:mapping=>nil})
      self.class.all_xml_mapping_nodes(:mapping=>options[:mapping]).each do |node|
        node.obj_initializing(self,options[:mapping])
      end
    end

    # Initializer. Called (by Class#new) after _self_ was created
    # using _new_.
    #
    # XML::Mapping's implementation calls #initialize_xml_mapping.
    def initialize(*args)
      super(*args)
      initialize_xml_mapping
    end

    # "fill" the contents of _xml_ into _self_. _xml_ is a
    # REXML::Element.
    #
    # First, pre_load(_xml_) is called, then all the nodes for this
    # object's class are processed (i.e. have their
    # #xml_to_obj method called) in the order of their definition
    # inside the class, then #post_load is called.
    def fill_from_xml(xml, options={:mapping=>:_default})
      raise(MappingError, "undefined mapping: #{options[:mapping].inspect}") \
        unless self.class.xml_mapping_nodes_hash.has_key?(options[:mapping])
      pre_load xml, :mapping=>options[:mapping]
      self.class.all_xml_mapping_nodes(:mapping=>options[:mapping]).each do |node|
        node.xml_to_obj self, xml
      end
      post_load :mapping=>options[:mapping]
    end

    # This method is called immediately before _self_ is filled from
    # an xml source. _xml_ is the source REXML::Element.
    #
    # The default implementation of this method is empty.
    def pre_load(xml, options={:mapping=>:_default})
    end

    
    # This method is called immediately after _self_ has been filled
    # from an xml source. If you have things to do after the object
    # has been succefully loaded from the xml (reorganising the loaded
    # data in some way, setting up additional views on the data etc.),
    # this is the place where you put them. You can also raise an
    # exception to abandon the whole loading process.
    #
    # The default implementation of this method is empty.
    def post_load(options={:mapping=>:_default})
    end


    # Fill _self_'s state into the xml node (REXML::Element)
    # _xml_. All the nodes for this object's class are processed
    # (i.e. have their
    # #obj_to_xml method called) in the order of their definition
    # inside the class.
    def fill_into_xml(xml, options={:mapping=>:_default})
      self.class.all_xml_mapping_nodes(:mapping=>options[:mapping]).each do |node|
        node.obj_to_xml self,xml
      end
    end

    # Fill _self_'s state into a new xml node, return that
    # node.
    #
    # This method calls #pre_save, then #fill_into_xml, then
    # #post_save.
    def save_to_xml(options={:mapping=>:_default})
      xml = pre_save :mapping=>options[:mapping]
      fill_into_xml xml, :mapping=>options[:mapping]
      post_save xml, :mapping=>options[:mapping]
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
    def pre_save(options={:mapping=>:_default})
      REXML::Element.new(self.class.root_element_name(:mapping=>options[:mapping]))
    end

    # This method is called immediately after _self_'s state has been
    # filled into an XML element.
    #
    # The default implementation does nothing.
    def post_save(xml, options={:mapping=>:_default})
    end


    # Save _self_'s state as XML into the file named _filename_.
    # The XML is obtained by calling #save_to_xml.
    def save_to_file(filename, options={:mapping=>:_default})
      xml = save_to_xml :mapping=>options[:mapping]
      File.open(filename,"w") do |f|
        REXML::Formatters::Transitive.new(2,false).write(xml,f)
      end
    end


    # The instance methods of this module are automatically added as
    # class methods to a class that includes XML::Mapping.
    module ClassMethods
    #ClassMethods = Module.new do  # this is the alternative -- but see above for peculiarities

      # all nodes of this class, in the order of their definition,
      # hashed by mapping (hash mapping => array of nodes)
      def xml_mapping_nodes_hash    #:nodoc:
        @xml_mapping_nodes ||= {}
      end

      # called on a class when it is being made a mapping class
      # (i.e. immediately after XML::Mapping was included in it)
      def initializing_xml_mapping  #:nodoc:
        @default_mapping = :_default
      end

      # Make _mapping_ the mapping to be used by default in future
      # node declarations in this class. The default can be
      # overwritten on a per-node basis by passing a :mapping option
      # parameter to the node factory method
      #
      # The initial default mapping in a mapping class is :_default
      def use_mapping mapping
        @default_mapping = mapping
        xml_mapping_nodes_hash[mapping] ||= []  # create empty mapping node list if
                                                # there wasn't one before so future calls
                                                # to load/save_xml etc. w/ this mapping don't raise
      end

      # return the current default mapping (:_default initially, or
      # the value set with the latest call to use_mapping)
      def default_mapping
        @default_mapping
      end

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
      def load_from_file(filename, options={:mapping=>:_default})
        xml = REXML::Document.new(File.new(filename))
        load_from_xml xml.root, :mapping=>options[:mapping]
      end

      # Create a new instance of this class from the XML contained in
      # _xml_ (a REXML::Element).
      #
      # Allocates a new object, then calls fill_from_xml(_xml_) on
      # it.
      def load_from_xml(xml, options={:mapping=>:_default})
        raise(MappingError, "undefined mapping: #{options[:mapping].inspect}") \
          unless xml_mapping_nodes_hash.has_key?(options[:mapping])
        # create the new object. It is recommended that the class
        # have a no-argument initializer, so try new first. If that
        # doesn't work, try allocate, which bypasses the initializer.
        begin
          obj = self.new
        rescue ArgumentError # TODO: this may hide real errors.
                             #   how to statically check whether
                             #   self self.new accepts an empty
                             #   argument list?
          obj = self.allocate
        end
        obj.initialize_xml_mapping :mapping=>options[:mapping]
        obj.fill_from_xml xml, :mapping=>options[:mapping]
        obj
      end


      # array of all nodes defined in this class, in the order of
      # their definition. Option :create specifies whether or not an
      # empty array should be created and returned if there was none
      # before (if not, an exception is raised). :mapping specifies
      # the mapping the returned nodes must have been defined in; nil
      # means return all nodes regardless of their mapping
      def xml_mapping_nodes(options={:mapping=>nil,:create=>true})
        unless options[:mapping]
          return xml_mapping_nodes_hash.values.inject([]){|a1,a2|a1+a2}
        end
        options[:create] = true if options[:create].nil?
        if options[:create]
          xml_mapping_nodes_hash[options[:mapping]] ||= []
        else
          xml_mapping_nodes_hash[options[:mapping]] ||
            raise(MappingError, "undefined mapping: #{options[:mapping].inspect}")
        end
      end


      # enumeration of all nodes in effect when
      # marshalling/unmarshalling this class, that is, nodes defined
      # for this class as well as for its superclasses.  The nodes are
      # returned in the order of their definition, starting with the
      # topmost superclass that has nodes defined. keyword arguments
      # are the same as for #xml_mapping_nodes.
      def all_xml_mapping_nodes(options={:mapping=>nil,:create=>true})
        # TODO: we could return a dynamic Enumerable here, or cache
        # the array...
        result = []
        if superclass and superclass.respond_to?(:all_xml_mapping_nodes)
          result += superclass.all_xml_mapping_nodes options
        end
        result += xml_mapping_nodes options
      end


      # The "root element name" of this class (combined getter/setter
      # method).
      #
      # The root element name is the name of the root element of the
      # XML tree returned by <this class>.#save_to_xml (or, more
      # specifically, <this class>.#pre_save). By default, this method
      # returns the #default_root_element_name; you may call this
      # method with an argument to set the root element name to
      # something other than the default. The option argument :mapping
      # specifies the mapping the root element is/will be defined in,
      # it defaults to the current default mapping (:_default
      # initially, or the value set with the latest call to
      # use_mapping)
      def root_element_name(name=nil, options={:mapping=>@default_mapping})
        if Hash===name    # ugly...
          options=name; name=nil
        end
        @root_element_names ||= {}
        if name
          Classes_by_rootelt_names.remove_class root_element_name, options[:mapping], self
          @root_element_names[options[:mapping]] = name
          Classes_by_rootelt_names.create_classes_for(name, options[:mapping]) << self
        end
        @root_element_names[options[:mapping]] || default_root_element_name
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
    # object, which is returned. The class of the object and the
    # mapping to be used for unmarshalling are automatically
    # determined from the root element name of _xml_ using
    # XML::Mapping.class_for_root_elt_name. If :mapping is non-nil,
    # only root element names defined in that mapping will be
    # considered (default is to consider all classes)
    def self.load_object_from_xml(xml,options={:mapping=>nil})
      if mapping = options[:mapping]
        c = class_for_root_elt_name xml.name, :mapping=>mapping
      else
        c,mapping = class_and_mapping_for_root_elt_name(xml.name)
      end
      unless c
        raise MappingError, "no mapping class for root element name #{xml.name}, mapping #{mapping.inspect}"
      end
      c.load_from_xml xml, :mapping=>mapping
    end

    # Like load_object_from_xml, but loads from the XML file named by
    # _filename_.
    def self.load_object_from_file(filename,options={:mapping=>nil})
      xml = REXML::Document.new(File.new(filename))
      load_object_from_xml xml.root, options
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


    ###### core node classes

    # Abstract base class for all node types. As mentioned in the
    # documentation for XML::Mapping, node types must be registered
    # using XML::Mapping.add_node_class, and a corresponding "node
    # factory method" (e.g. "text_node") will then be added as a class
    # method to your mapping classes. The node factory method is
    # called from the body of the mapping classes as demonstrated in
    # the examples. It creates an instance of its corresponding node
    # type (the list of parameters to the node factory method,
    # preceded by the owning mapping class, will be passed to the
    # constructor of the node type) and adds it to its owning mapping
    # class, so there is one node object per node definition per
    # mapping class. That node object will handle all XML
    # marshalling/unmarshalling for this node, for all instances of
    # the mapping class. For this purpose, the marshalling and
    # unmarshalling methods of a mapping class instance (fill_into_xml
    # and fill_from_xml, respectively) will call obj_to_xml
    # resp. xml_to_obj on all nodes of the mapping class, in the order
    # of their definition, passing the REXML element the data is to be
    # marshalled to/unmarshalled from as well as the object the data
    # is to be read from/filled into.
    #
    # Node types that map some XML data to a single attribute of their
    # mapping class (that should be most of them) shouldn't be
    # directly derived from this class, but rather from
    # SingleAttributeNode.
    class Node
      # Intializer, to be called from descendant classes. _owner_ is
      # the mapping class this node is being defined in. It'll be
      # stored in _@owner_. @options will be set to a (possibly empty)
      # hash containing the option arguments passed to
      # _initialize_. Options :mapping, :reader and :writer will be
      # handled, subclasses may handle additional options. See the
      # section on defining nodes in the README for details.
      def initialize(owner,*args)
        @owner = owner
        if Hash===args[-1]
          @options = args[-1]
          args = args[0..-2]
        else
          @options={}
        end
        @mapping = @options[:mapping] || owner.default_mapping
        owner.xml_mapping_nodes(:mapping=>@mapping) << self
        XML::Mapping::Classes_by_rootelt_names.ensure_exists owner.root_element_name, @mapping, owner
        if @options[:reader]
          # override xml_to_obj in this instance with invocation of
          # @options[:reader]
          class << self
            alias_method :default_xml_to_obj, :xml_to_obj
            def xml_to_obj(obj,xml)
              begin
                @options[:reader].call(obj,xml,self.method(:default_xml_to_obj))
              rescue ArgumentError  # thrown if @options[:reader] is a lambda (i.e. no Proc) with !=3 args (e.g. proc{...} in ruby1.8)
                @options[:reader].call(obj,xml)
              end
            end
          end
        end
        if @options[:writer]
          # override obj_to_xml in this instance with invocation of
          # @options[:writer]
          class << self
            alias_method :default_obj_to_xml, :obj_to_xml
            def obj_to_xml(obj,xml)
              begin
                @options[:writer].call(obj,xml,self.method(:default_obj_to_xml))
              rescue ArgumentError # thrown if (see above)
                @options[:writer].call(obj,xml)
              end
            end
          end
        end
        args
      end
      # This is called by the XML unmarshalling machinery when the
      # state of an instance of this node's @owner is to be read from
      # an XML tree. _obj_ is the instance, _xml_ is the tree (a
      # REXML::Element). The node must read "its" data from _xml_
      # (using XML::XXPath or any other means) and store it to the
      # corresponding parts (attributes etc.) of _obj_'s state.
      def xml_to_obj(obj,xml)
        raise "abstract method called"
      end
      # This is called by the XML unmarshalling machinery when the
      # state of an instance of this node's @owner is to be stored
      # into an XML tree. _obj_ is the instance, _xml_ is the tree (a
      # REXML::Element). The node must extract "its" data from _obj_
      # and store it to the corresponding parts (sub-elements,
      # attributes etc.) of _xml_ (using XML::XXPath or any other
      # means).
      def obj_to_xml(obj,xml)
        raise "abstract method called"
      end
      # Called when a new instance of the mapping class this node
      # belongs to is being initialized. _obj_ is the
      # instance. _mapping_ is the mapping the initialization is
      # happening with, if any: If the instance is being initialized
      # as part of e.g. <tt>Class.load_from_file(name,
      # :mapping=>:some_mapping</tt> or any other call that specifies
      # a mapping, that mapping will be passed to this method. If the
      # instance is being initialized normally with
      # <tt>Class.new</tt>, _mapping_ is nil here.
      #
      # You may set up initial values for the attributes this node is
      # responsible for here. Default implementation is empty.
      def obj_initializing(obj,mapping)
      end
      # tell whether this node's data is present in _obj_ (when this
      # method is called, _obj_ will be an instance of the mapping
      # class this node was defined in). This method is currently used
      # only by ChoiceNode when writing data back to XML. See
      # ChoiceNode#obj_to_xml.
      def is_present_in? obj
        true
      end
    end


    # Base class for node types that map some XML data to a single
    # attribute of their mapping class.
    #
    # All node types that come with xml-mapping except one
    # (ChoiceNode) inherit from SingleAttributeNode.
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
      # In the initializer, two option arguments -- :optional and
      # :default_value -- are processed in SingleAttributeNode:
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
      def initialize(*args)
        @attrname,*args = super(*args)
        @owner.add_accessor @attrname
        if @options[:optional] and not(@options.has_key?(:default_value))
          @options[:default_value] = nil
        end
        initialize_impl(*args)
        args
      end
      # this method was retained for compatibility with xml-mapping 0.8.
      #
      # It used to be the initializer to be implemented by subclasses. The
      # arguments (args) are those still unprocessed by
      # SingleAttributeNode's initializer.
      #
      # In xml-mapping 0.9 and up, you should just override initialize() and
      # call super.initialize. The returned array is the same args array.
      def initialize_impl(*args)
      end

      # Exception that may be used by implementations of
      # #extract_attr_value to announce that the attribute value is
      # not set in the XML and, consequently, the default value should
      # be set in the object being created, or an Exception be raised
      # if no default value was specified.
      class NoAttrValueSet < XXPathError
      end

      def xml_to_obj(obj,xml)  # :nodoc:
        begin
          obj.send :"#{@attrname}=", extract_attr_value(xml)
        rescue NoAttrValueSet => err
          unless @options.has_key? :default_value
            raise XML::MappingError, "no value, and no default value: #{err}"
          end
          begin
            obj.send :"#{@attrname}=", @options[:default_value].clone
          rescue
            obj.send :"#{@attrname}=", @options[:default_value]
          end
        end
        true
      end

      # (to be overridden by subclasses) Extract and return the value
      # of the attribute this node is responsible for (@attrname) from
      # _xml_. If the implementation decides that the attribute value
      # is "unset" in _xml_, it should raise NoAttrValueSet in order
      # to initiate proper handling of possibly supplied :optional and
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
            raise XML::MappingError, "no value, and no default value, for attribute: #{@attrname}"
          end
          set_attr_value(xml, value)
        end
        true
      end
      # (to be overridden by subclasses) Write _value_, which is the
      # current value of the attribute this node is responsible for
      # (@attrname), into (the correct sub-nodes, attributes,
      # whatever) of _xml_.
      def set_attr_value(xml, value)
        raise "abstract method called"
      end
      def obj_initializing(obj,mapping)  # :nodoc:
        if @options.has_key?(:default_value) and (mapping==nil || mapping==@mapping)
          begin
            obj.send :"#{@attrname}=", @options[:default_value].clone
          rescue
            obj.send :"#{@attrname}=", @options[:default_value]
          end
        end
      end
      # utility method to be used by implementations of
      # #extract_attr_value. Calls the supplied block, catching
      # XML::XXPathError and mapping it to NoAttrValueSet. This is for
      # the common case that an implementation considers an attribute
      # value not to be present in the XML if some specific sub-path
      # does not exist.
      def default_when_xpath_err # :yields:
        begin
          yield
        rescue XML::XXPathError => err
          raise NoAttrValueSet, "Attribute #{@attrname} not set (XXPathError: #{err})"
        end
      end
      # (overridden) returns true if and only if the value of this
      # node's attribute in _obj_ is non-nil.
      def is_present_in? obj
        nil != obj.send(:"#{@attrname}")
      end
    end

  end

end
