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
      def extract_attr_value(xml)
        default_when_xpath_err{ @path.first(xml).text }
      end
      def set_attr_value(xml, value)
        @path.first(xml,:ensure_created=>true).text = value
      end
    end

    # Like TextNode, but interprets the XML node's text as an integer
    # and maps it to an integer attribute.
    class IntNode < SingleAttributeNode
      def initialize_impl(path)
        @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml)
        default_when_xpath_err{ @path.first(xml).text.to_i }
      end
      def set_attr_value(xml, value)
        raise RuntimeError, "Not an integer: #{value}" unless Integer===value
        @path.first(xml,:ensure_created=>true).text = value.to_s
      end
    end

    # Node that maps a subtree in the source XML to an instance of a
    # specific mapping class.
    class ObjectNode < SingleAttributeNode
      # Initializer. _klass_ is the mapping class the subtree gets
      # mapped to (klass must support XML mapping, i.e. it must
      # include XML::Mapping), _path_ (a string denoting an XPath
      # expression) is the location of the subtree.
      def initialize_impl(klass,path)
        @klass = klass; @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml)
        @klass.load_from_rexml(default_when_xpath_err{@path.first(xml)})
      end
      def set_attr_value(xml, value)
        value.fill_into_rexml(@path.first(xml,:ensure_created=>true))
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
      def extract_attr_value(xml)
        default_when_xpath_err{ @path.first(xml).text==@true_value }
      end
      def set_attr_value(xml, value)
        @path.first(xml,:ensure_created=>true).text = value ? @true_value : @false_value
      end
    end

    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing an array of instances of a specific mapping
    # class, with each array element mapping to a corresponding member
    # of the sequence of sub-nodes.
    class ArrayNode < SingleAttributeNode
      # Initializer, delegates to do_initialize. Called with a class
      # (_klass_) and either 1 or 2 paths; the hindmost path argument
      # passed is delegated to _per_arrelement_path_; the preceding
      # path argument (if present, "" by default) is delegated to
      # _base_path_. _klass_ is delegated to _klass_.
      def initialize_impl(klass,path,path2=nil)
	if path2
	  do_initialize(klass,path,path2)
	else
	  do_initialize(klass,"",path)
	end
      end
      # "Real"
      # initializer. _base_path_+<tt>"/"</tt>+_per_arrelement_path_ is
      # the XPath expression that must "yield" the mentioned sequence
      # of XML nodes that is to be mapped to the array. _klass_ is the
      # class of all the array's elements; it must be a mapping class,
      # and each element of the array is mapped to the corresponding
      # XML node in the sequence of XML nodes yielded by the XPath
      # expression.
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
      def do_initialize(klass,base_path,per_arrelement_path)
        @klass = klass;
	per_arrelement_path=per_arrelement_path[1..-1] if per_arrelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_arrelement_path = XML::XPath.new(per_arrelement_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_arrelement_path)
      end
      def extract_attr_value(xml)
        result = []
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          result << @klass.load_from_rexml(elt)
        end
        result
      end
      def set_attr_value(xml, value)
	base_elt = @base_path.first(xml,:ensure_created=>true)
	value.each do |arr_elt|
	  arr_elt.fill_into_rexml(@per_arrelement_path.create_new(base_elt))
	end
      end
    end


    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing a hash of instances of a specific mapping
    # class, with each hash value mapping to a corresponding member of
    # the sequence of sub-nodes. The (string-valued) hash key
    # associated with a hash value _v_ is mapped to the text of a
    # specific sub-node of _v_'s sub-node.
    class HashNode < SingleAttributeNode
      # Initializer, delegates to do_initialize. Called with a class
      # (_klass_) and either 2 or 3 paths; the hindmost path argument
      # passed is delegated to _key_path_, the preceding path argument
      # is delegated to _per_arrelement_path_, the path preceding that
      # argument (if present, "" by default) is delegated to
      # _base_path_. _klass_ is delegated to _klass_.
      def initialize_impl(klass,path1,path2,path3=nil)
        if path3
          do_initialize(klass,path1,path2,path3)
        else
          do_initialize(klass,"",path1,path2)
        end
      end
      # "Real" initializer. Analogously to ArrayNode, _base_path_ and
      # _per_arrelement_path_ define the XPath expression that
      # "yields" the sequence of XML nodes, each of which maps to a
      # value in the hash table. Relative to such a node, key_path_
      # names the node whose text becomes the associated hash key.
      def do_initialize(klass,base_path,per_hashelement_path,key_path)
        @klass = klass;
	per_hashelement_path=per_hashelement_path[1..-1] if per_hashelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_hashelement_path = XML::XPath.new(per_hashelement_path)
	@key_path = XML::XPath.new(key_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_hashelement_path)
      end
      def extract_attr_value(xml)
        result = {}
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          key = @key_path.first(elt).text
          value = @klass.load_from_rexml(elt)
          result[key] = value
        end
        result
      end
      def set_attr_value(xml, value)
	base_elt = @base_path.first(xml,:ensure_created=>true)
	value.each_pair do |k,v|
          elt = @per_hashelement_path.create_new(base_elt)
	  v.fill_into_rexml(elt)
          @key_path.first(elt,:ensure_created=>true).text = k
	end
      end
    end

  end

end
