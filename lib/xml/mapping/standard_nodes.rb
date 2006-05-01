# xml-mapping -- bidirectional Ruby-XML mapper
#  Copyright (C) 2004,2005 Olaf Klischat

module XML

  module Mapping

    # Node factory function synopsis:
    # 
    #   text_node :_attrname_, _path_ [, :default_value=>_obj_]
    #                                 [, :optional=>true]
    #
    # Node that maps an XML node's text (the element's first child
    # text node resp. the attribute's value) to a (string) attribute
    # of the mapped object. Since TextNode inherits from
    # SingleAttributeNode, the first argument to the node factory
    # function is the attribute name (as a symbol). Handling of
    # <tt>:default_value</tt> and <tt>:optional</tt> option arguments
    # (if given) is also provided by the superclass -- see there for
    # details.
    class TextNode < SingleAttributeNode
      # Initializer. _path_ (a string, the 2nd argument to the node
      # factory function) is the XPath expression that locates the
      # mapped node in the XML.
      def initialize(*args)
        path,*args = super(*args)
        @path = XML::XXPath.new(path)
        args
      end
      def extract_attr_value(xml) # :nodoc:
        default_when_xpath_err{ @path.first(xml).text }
      end
      def set_attr_value(xml, value) # :nodoc:
        @path.first(xml,:ensure_created=>true).text = value
      end
    end

    # Node factory function synopsis:
    # 
    #   numeric_node :_attrname_, _path_ [, :default_value=>_obj_]
    #                                    [, :optional=>true]
    #
    # Like TextNode, but interprets the XML node's text as a number
    # (Integer or Float, depending on the nodes's text) and maps it to
    # an Integer or Float attribute.
    class NumericNode < SingleAttributeNode
      def initialize(*args)
        path,*args = super(*args)
        @path = XML::XXPath.new(path)
        args
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

    # (does somebody have a better name for this class?) base node
    # class that provides an initializer which lets the user specify a
    # means to marshal/unmarshal a Ruby object to/from XML. Used as
    # the base class for nodes that map some sub-nodes of their XML
    # tree to (Ruby-)sub-objects of their attribute.
    class SubObjectBaseNode < SingleAttributeNode
      # processes the keyword arguments :class, :marshaller, and
      # :unmarshaller (_args_ is ignored). When this initiaizer
      # returns, @options[:marshaller] and @options[:unmarshaller] are
      # set to procs that marshal/unmarshal a Ruby object to/from an
      # XML tree according to the keyword arguments that were passed
      # to the initializer:
      #
      # You either supply a :class argument with a class implementing
      # XML::Mapping -- in that case, the subtree will be mapped to an
      # instance of that class (using load_from_xml
      # resp. fill_into_xml). Or, you supply :marshaller and
      # :unmarshaller arguments specifying explicit
      # unmarshaller/marshaller procs. The :marshaller proc takes
      # arguments _xml_,_value_ and must fill _value_ (the object to
      # be marshalled) into _xml_; the :unmarshaller proc takes _xml_
      # and must extract and return the object value from it. Or, you
      # specify none of those arguments, in which case the name of the
      # class to create will be automatically deduced from the root
      # element name of the XML node (see
      # XML::Mapping::load_object_from_xml,
      # XML::Mapping::class_for_root_elt_name).
      #
      # If both :class and :marshaller/:unmarshaller arguments are
      # supplied, the latter take precedence.
      def initialize(*args)
        args = super(*args)

        @sub_mapping = @options[:sub_mapping] || @mapping
        @marshaller, @unmarshaller = @options[:marshaller], @options[:unmarshaller]

        if @options[:class]
          unless @marshaller
            @marshaller = proc {|xml,value|
              value.fill_into_xml xml, :mapping=>@sub_mapping
            }
          end
          unless @unmarshaller
            @unmarshaller = proc {|xml|
              @options[:class].load_from_xml xml, :mapping=>@sub_mapping
            }
          end
        end

        unless @marshaller
          @marshaller = proc {|xml,value|
            value.fill_into_xml xml, :mapping=>@sub_mapping
            if xml.unspecified?
              xml.name = value.class.root_element_name :mapping=>@sub_mapping
              xml.unspecified = false
            end
          }
        end
        unless @unmarshaller
          @unmarshaller = proc {|xml|
            XML::Mapping.load_object_from_xml xml, :mapping=>@sub_mapping
          }
        end

        args
      end
    end

    require 'xml/mapping/core_classes_mapping'

    # Node factory function synopsis:
    # 
    #   object_node :_attrname_, _path_ [, :default_value=>_obj_]
    #                                   [, :optional=>true]
    #                                   [, :class=>_c_]
    #                                   [, :marshaller=>_proc_]
    #                                   [, :unmarshaller=>_proc_]
    #
    # Node that maps a subtree in the source XML to a Ruby
    # object. :_attrname_ and _path_ are again the attribute name
    # resp. XPath expression of the mapped attribute; the keyword
    # arguments <tt>:default_value</tt> and <tt>:optional</tt> are
    # handled by the SingleAttributeNode superclass. The XML subnode
    # named by _path_ is mapped to the attribute named by :_attrname_
    # according to the keyword arguments <tt>:class</tt>,
    # <tt>:marshaller</tt>, and <tt>:unmarshaller</tt>, which are
    # handled by the SubObjectBaseNode superclass.
    class ObjectNode < SubObjectBaseNode
      # Initializer. _path_ (a string denoting an XPath expression) is
      # the location of the subtree.
      def initialize(*args)
        path,*args = super(*args)
        @path = XML::XXPath.new(path)
        args
      end
      def extract_attr_value(xml) # :nodoc:
        @unmarshaller.call(default_when_xpath_err{@path.first(xml)})
      end
      def set_attr_value(xml, value) # :nodoc:
        @marshaller.call(@path.first(xml,:ensure_created=>true), value)
      end
    end

    # Node factory function synopsis:
    # 
    #   boolean_node :_attrname_, _path_,
    #                _true_value_, _false_value_ [, :default_value=>_obj_]
    #                                            [, :optional=>true]
    #
    # Node that maps an XML node's text (the element name resp. the
    # attribute value) to a boolean attribute of the mapped
    # object. The attribute named by :_attrname_ is mapped to/from the
    # XML subnode named by the XPath expression _path_. _true_value_
    # is the text the node must have in order to represent the +true+
    # boolean value, _false_value_ (actually, any value other than
    # _true_value_) is the text the node must have in order to
    # represent the +false+ boolean value.
    class BooleanNode < SingleAttributeNode
      # Initializer.
      def initialize(*args)
        path,true_value,false_value,*args = super(*args)
        @path = XML::XXPath.new(path)
        @true_value = true_value; @false_value = false_value
        args
      end
      def extract_attr_value(xml) # :nodoc:
        default_when_xpath_err{ @path.first(xml).text==@true_value }
      end
      def set_attr_value(xml, value) # :nodoc:
        @path.first(xml,:ensure_created=>true).text = value ? @true_value : @false_value
      end
    end

    # Node factory function synopsis:
    # 
    #   array_node :_attrname_, _per_arrelement_path_
    #                     [, :default_value=>_obj_]
    #                     [, :optional=>true]
    #                     [, :class=>_c_]
    #                     [, :marshaller=>_proc_]
    #                     [, :unmarshaller=>_proc_]
    #
    # -or-
    #
    #   array_node :_attrname_, _base_path_, _per_arrelement_path_
    #                     [keyword args the same]
    #
    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing an array of Ruby objects, with each array
    # element mapping to a corresponding member of the sequence of
    # sub-nodes.
    #
    # If _base_path_ is not supplied, it is assumed to be
    # "". _base_path_+<tt>"/"</tt>+_per_arrelement_path_ is an XPath
    # expression that must "yield" the sequence of XML nodes that is
    # to be mapped to the array.  The difference between _base_path_
    # and _per_arrelement_path_ becomes important when marshalling the
    # array attribute back to XML. When that happens, _base_path_
    # names the most specific common parent node of all the mapped
    # sub-nodes, and _per_arrelement_path_ names (relative to
    # _base_path_) the part of the path that is duplicated for each
    # array element. For example, with _base_path_==<tt>"foo/bar"</tt>
    # and _per_arrelement_path_==<tt>"hi/ho"</tt>, an array
    # <tt>[x,y,z]</tt> will be written to an XML structure that looks
    # like this:
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
    class ArrayNode < SubObjectBaseNode
      # Initializer, delegates to do_initialize. Called with keyword
      # arguments and either 1 or 2 paths; the hindmost path argument
      # passed is delegated to _per_arrelement_path_; the preceding
      # path argument (if present, "" by default) is delegated to
      # _base_path_.
      def initialize(*args)
        path,path2,*args = super(*args)
        base_path,per_arrelement_path = if path2
                                          [path,path2]
                                        else
                                          [".",path]
                                        end
        per_arrelement_path=per_arrelement_path[1..-1] if per_arrelement_path[0]==?/
        @base_path = XML::XXPath.new(base_path)
        @per_arrelement_path = XML::XXPath.new(per_arrelement_path)
        @reader_path = XML::XXPath.new(base_path+"/"+per_arrelement_path)
        args
      end
      def extract_attr_value(xml) # :nodoc:
        result = []
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          result << @unmarshaller.call(elt)
        end
        result
      end
      def set_attr_value(xml, value) # :nodoc:
        base_elt = @base_path.first(xml,:ensure_created=>true)
        value.each do |arr_elt|
          @marshaller.call(@per_arrelement_path.create_new(base_elt), arr_elt)
        end
      end
    end


    # Node factory function synopsis:
    # 
    #   hash_node :_attrname_, _per_hashelement_path_, _key_path_
    #                     [, :default_value=>_obj_]
    #                     [, :optional=>true]
    #                     [, :class=>_c_]
    #                     [, :marshaller=>_proc_]
    #                     [, :unmarshaller=>_proc_]
    #
    # - or -
    #
    #   hash_node :_attrname_, _base_path_, _per_hashelement_path_, _key_path_
    #                     [keyword args the same]
    #
    # Node that maps a sequence of sub-nodes of the XML tree to an
    # attribute containing a hash of Ruby objects, with each hash
    # value mapping to a corresponding member of the sequence of
    # sub-nodes. The (string-valued) hash key associated with a hash
    # value _v_ is mapped to the text of a specific sub-node of _v_'s
    # sub-node.
    #
    # Analogously to ArrayNode, _base_path_ and _per_arrelement_path_
    # define the XPath expression that "yields" the sequence of XML
    # nodes, each of which maps to a value in the hash table. Relative
    # to such a node, key_path_ names the node whose text becomes the
    # associated hash key.
    class HashNode < SubObjectBaseNode
      # Initializer, delegates to do_initialize. Called with keyword
      # arguments and either 2 or 3 paths; the hindmost path argument
      # passed is delegated to _key_path_, the preceding path argument
      # is delegated to _per_arrelement_path_, the path preceding that
      # argument (if present, "" by default) is delegated to
      # _base_path_. The meaning of the keyword arguments is the same
      # as for ObjectNode.
      def initialize(*args)
        path1,path2,path3,*args = super(*args)
        base_path,per_hashelement_path,key_path = if path3
                                                    [path1,path2,path3]
                                                  else
                                                    ["",path1,path2]
                                                  end
        per_hashelement_path=per_hashelement_path[1..-1] if per_hashelement_path[0]==?/
        @base_path = XML::XXPath.new(base_path)
        @per_hashelement_path = XML::XXPath.new(per_hashelement_path)
        @key_path = XML::XXPath.new(key_path)
        @reader_path = XML::XXPath.new(base_path+"/"+per_hashelement_path)
        args
      end
      def extract_attr_value(xml) # :nodoc:
        result = {}
        default_when_xpath_err{@reader_path.all(xml)}.each do |elt|
          key = @key_path.first(elt).text
          value = @unmarshaller.call(elt)
          result[key] = value
        end
        result
      end
      def set_attr_value(xml, value) # :nodoc:
        base_elt = @base_path.first(xml,:ensure_created=>true)
        value.each_pair do |k,v|
          elt = @per_hashelement_path.create_new(base_elt)
          @marshaller.call(elt,v)
          @key_path.first(elt,:ensure_created=>true).text = k
        end
      end
    end


    class ChoiceNode < Node

      def initialize(*args)
        args = super(*args)
        @choices = []
        path=nil
        args.each do |arg|
          next if [:if,:then,:elsif].include? arg
          if path.nil?
            path = (if [:else,:default,:otherwise].include? arg
                      :else
                    else
                      XML::XXPath.new arg
                    end)
          else
            raise XML::MappingError, "node expected, found: #{arg.inspect}" unless Node===arg
            @choices << [path,arg]

            # undo what the node factory fcn did -- ugly ugly!  would
            # need some way to lazy-evaluate arg (a proc would be
            # simple but ugly for the user), and then use some
            # mechanism (a flag with dynamic scope probably) to tell
            # the node factory fcn not to add the node to the
            # xml_mapping_nodes
            @owner.xml_mapping_nodes(:mapping=>@mapping).delete arg 
            path=nil
          end
        end

        raise XML::MappingError, "node missing at end of argument list" unless path.nil?
        raise XML::MappingError, "no choices were supplied" if @choices.empty?
        
        []
      end

      def xml_to_obj(obj,xml)
        @choices.each do |path,node|
          if path==:else or not(path.all(xml).empty?)
            node.xml_to_obj(obj,xml)
            return true
          end
        end
        raise XML::MappingError, "xml_to_obj: no choice matched in: #{xml}"
      end

      def obj_to_xml(obj,xml)
        @choices.each do |path,node|
          if node.is_present_in? obj
            node.obj_to_xml(obj,xml)
            path.first(xml, :ensure_created=>true)
            return true
          end
        end
        # @choices[0][1].obj_to_xml(obj,xml)
        raise XML::MappingError, "obj_to_xml: no choice present in object: #{obj.inspect}"
      end

      def obj_initializing(obj,mapping)
        @choices[0][1].obj_initializing(obj,mapping)
      end

      # (overridden) true if at least one of our nodes is_present_in?
      # obj.
      def is_present_in? obj
        @choices.inject(false){|prev,(path,node)| prev or node.is_present_in?(obj)}
      end
    end

  end

end
