module XML

  module Mapping

    # Node that maps an XML node's text (the element's first child
    # text node resp. the attribute's value) to a (string) attribute
    # of the mapped object. Since TextNode inherits from
    # SingleAttributeNode, the first argument to the node factory
    # function is the attribute name (as a symbol).
    class TextNode < SingleAttributeNode
      # Initializer. _path_ (a string, the 2nd argument to the node
      # factory function) is the XPath expression that locates the
      # mapped node in the XML.
      def initialize_impl(path)
        @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml) # :nodoc:
        default_when_xpath_err{ @path.first(xml).text }
      end
      def set_attr_value(xml, value) # :nodoc:
        @path.first(xml,:ensure_created=>true).text = value
      end
    end

    # Like TextNode, but interprets the XML node's text as a number
    # (Integer or Float, depending on the nodes's text) and maps it to
    # an Integer or Float attribute.
    class NumericNode < SingleAttributeNode
      def initialize_impl(path)
        @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml) # :nodoc:
        txt = default_when_xpath_err{ @path.first(xml).text }
        begin
          Integer(txt)
        rescue ArgumentError
          Float(txt)
        end
      end
      def set_attr_value(xml, value) # :nodoc:
        raise RuntimeError, "Not an integer: #{value}" unless Numeric===value
        @path.first(xml,:ensure_created=>true).text = value.to_s
      end
    end

    # abstract base class for nodes whose initializers support :class
    # and :marshaller, :unmarshaller keyword arguments
    class ClassAndMarshallingSupportNode < SingleAttributeNode
      # processes the @options :class, :marshaller, and :unmarshaller
      # (args are ignored). See documentation of ObjectNode for
      # details on the meaning of these options.
      def initialize_impl(*args)
        if @options[:class]
          unless @options[:marshaller]
            @options[:marshaller] = proc {|xml,value|
              value.fill_into_xml(xml)
            }
          end
          unless @options[:unmarshaller]
            @options[:unmarshaller] = proc {|xml|
              @options[:class].load_from_xml(xml)
            }
          end
        end
        unless @options[:marshaller] && @options[:unmarshaller]
          raise "#{@attrname}: option :class or options :marshaller & :unmarshaller required"
        end
      end
    end

    # Node that maps a subtree in the source XML to a Ruby object
    class ObjectNode < ClassAndMarshallingSupportNode
      # Initializer. _path_ (a string denoting an XPath expression) is
      # the location of the subtree. The object the subtree is
      # marshalled to/unmarshalled from is specified using keyword
      # arguments: You either supply a :class argument with a class
      # implementing XML::Mapping -- in that case, the subtree will be
      # mapped to an instance of that class (using load_from_xml
      # resp. fill_into_xml). Or, you supply :marshaller and
      # :unmarshaller arguments specifying explicit
      # unmarshaller/marshaller procs. The :marshaller proc takes
      # arguments _xml_,_value_ and must fill _value_ (the object to
      # be marshalled) into _xml_; the :unmarshaller proc takes _xml_
      # and must extract and return the object value from it.
      #
      # If both :class and :marshaller/:unmarshaller arguments are
      # supplied, the latter take precedence.
      def initialize_impl(path)
        super
	@path = XML::XPath.new(path)
      end
      def extract_attr_value(xml) # :nodoc:
        @options[:unmarshaller].call(default_when_xpath_err{@path.first(xml)})
      end
      def set_attr_value(xml, value) # :nodoc:
        @options[:marshaller].call(@path.first(xml,:ensure_created=>true), value)
      end
    end

    # Node that maps an XML node's text (the element name resp. the
    # attribute value) to a boolean attribute of the mapped
    # object.
    class BooleanNode < SingleAttributeNode
      # Initializer. _path_ (a string) is an XPath expression locating
      # the XML node, _true_value_ is the text the node must have in
      # order to represent the +true+ boolean value, _false_value_
      # (actually, any value other than _true_value_) is the text the
      # node must have in order to represent the +false+ boolean value.
      def initialize_impl(path,true_value,false_value)
        @path = XML::XPath.new(path)
        @true_value = true_value; @false_value = false_value
      end
      def extract_attr_value(xml) # :nodoc:
        default_when_xpath_err{ @path.first(xml).text==@true_value }
      end
      def set_attr_value(xml, value) # :nodoc:
        @path.first(xml,:ensure_created=>true).text = value ? @true_value : @false_value
      end
    end

    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing an array of Ruby objects, with each array
    # element mapping to a corresponding member of the sequence of
    # sub-nodes.
    class ArrayNode < ClassAndMarshallingSupportNode
      # Initializer, delegates to do_initialize. Called with keyword
      # arguments and either 1 or 2 paths; the hindmost path argument
      # passed is delegated to _per_arrelement_path_; the preceding
      # path argument (if present, "" by default) is delegated to
      # _base_path_. The meaning of the keyword arguments is the same
      # as for ObjectNode.
      def initialize_impl(path,path2=nil)
        super
	if path2
	  do_initialize(path,path2)
	else
	  do_initialize("",path)
	end
      end
      # "Real"
      # initializer. _base_path_+<tt>"/"</tt>+_per_arrelement_path_ is
      # the XPath expression that must "yield" the sequence of XML
      # nodes that is to be mapped to the array.
      #
      # The difference between _base_path_ and _per_arrelement_path_
      # becomes important when marshalling the array attribute back to
      # XML. When that happens, _base_path_ names the most specific
      # common parent node of all the mapped sub-nodes, and
      # _per_arrelement_path_ names (relative to _base_path_) the part
      # of the path that is duplicated for each array element. For
      # example, with _base_path_==<tt>"foo/bar"</tt> and
      # _per_arrelement_path_==<tt>"hi/ho"</tt>, an array
      # <tt>[x,y,z]</tt> will be written to an XML structure that
      # looks like this:
      #
      #   <foo>
      #    <bar>
      #     <hi>
      #      <ho>
      #       [marshalled object x]
      #      </ho>
      #     </hi>
      #     <hi>
      #      <ho>
      #       [marshalled object y]
      #      </ho>
      #     </hi>
      #     <hi>
      #      <ho>
      #       [marshalled object z]
      #      </ho>
      #     </hi>
      #    </bar>
      #   </foo>
      def do_initialize(base_path,per_arrelement_path)
	per_arrelement_path=per_arrelement_path[1..-1] if per_arrelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_arrelement_path = XML::XPath.new(per_arrelement_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_arrelement_path)
      end
      def extract_attr_value(xml) # :nodoc:
        result = []
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          result << @options[:unmarshaller].call(elt)
        end
        result
      end
      def set_attr_value(xml, value) # :nodoc:
	base_elt = @base_path.first(xml,:ensure_created=>true)
	value.each do |arr_elt|
          @options[:marshaller].call(@per_arrelement_path.create_new(base_elt), arr_elt)
	end
      end
    end


    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing a hash of Ruby objects, with each hash
    # value mapping to a corresponding member of the sequence of
    # sub-nodes. The (string-valued) hash key associated with a hash
    # value _v_ is mapped to the text of a specific sub-node of _v_'s
    # sub-node.
    class HashNode < ClassAndMarshallingSupportNode
      # Initializer, delegates to do_initialize. Called with keyword
      # arguments and either 2 or 3 paths; the hindmost path argument
      # passed is delegated to _key_path_, the preceding path argument
      # is delegated to _per_arrelement_path_, the path preceding that
      # argument (if present, "" by default) is delegated to
      # _base_path_. The meaning of the keyword arguments is the same
      # as for ObjectNode.
      def initialize_impl(path1,path2,path3=nil)
        super
        if path3
          do_initialize(path1,path2,path3)
        else
          do_initialize("",path1,path2)
        end
      end
      # "Real" initializer. Analogously to ArrayNode, _base_path_ and
      # _per_arrelement_path_ define the XPath expression that
      # "yields" the sequence of XML nodes, each of which maps to a
      # value in the hash table. Relative to such a node, key_path_
      # names the node whose text becomes the associated hash key.
      def do_initialize(base_path,per_hashelement_path,key_path)
	per_hashelement_path=per_hashelement_path[1..-1] if per_hashelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_hashelement_path = XML::XPath.new(per_hashelement_path)
	@key_path = XML::XPath.new(key_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_hashelement_path)
      end
      def extract_attr_value(xml) # :nodoc:
        result = {}
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          key = @key_path.first(elt).text
          value = @options[:unmarshaller].call(elt)
          result[key] = value
        end
        result
      end
      def set_attr_value(xml, value) # :nodoc:
	base_elt = @base_path.first(xml,:ensure_created=>true)
	value.each_pair do |k,v|
          elt = @per_hashelement_path.create_new(base_elt)
          @options[:marshaller].call(elt,v)
          @key_path.first(elt,:ensure_created=>true).text = k
	end
      end
    end

  end

end
