require 'rexml/document'
require "xml/xpath"

module XML

  module Mapping

    def self.append_features(base)
      super
      base.extend(ClassMethods)
      base.xmlmapping_init
    end


    def fill_from_rexml(xml)
      pre_load(xml)
      self.class.nodes.each do |node|
        node.xml_to_obj self, xml
      end
      post_load
    end

    def pre_load(xml)
    end

    def post_load
    end


    def fill_into_rexml(xml)
      self.class.nodes.each do |node|
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
      REXML::Document.new
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
        owner.nodes << self
      end
    end

    class TextNode < Node
      def initialize(owner,attrname,path)
        super(owner)
        @attrname = attrname; @path = XML::XPath.new(path)
      end
      def xml_to_obj(obj,xml)
        obj.send :"#{@attrname}=", @path.first(xml).text
      end
      def obj_to_xml(obj,xml)
        @path.first(xml,true).text = obj.send :"#{@attrname}"
      end
    end

    class IntNode < Node
      def initialize(owner,attrname,path,opts)
        super(owner)
        @attrname = attrname; @path = XML::XPath.new(path); @opts = opts
      end
      def xml_to_obj(obj,xml)
        begin
          obj.send :"#{@attrname}=", @path.first(xml).text.to_i
        rescue XML::XPathError
          raise unless @opts[:optional]
        end
      end
      def obj_to_xml(obj,xml)
        val = obj.send :"#{@attrname}"
        if val
          @path.first(xml,true).text = val.to_s
        else
          raise RuntimeError, "required attribute: #{@attrname}" unless @opts[:optional]
        end
      end
      # TODO: make :optional flag available as a general feature to all node types
    end

    class ObjectNode < Node
      def initialize(owner,attrname,klass,path)
        super(owner)
        @attrname = attrname; @klass = klass; @path = XML::XPath.new(path)
      end
      def xml_to_obj(obj,xml)
        obj.send :"#{@attrname}=", @klass.load_from_rexml(@path.first(xml))
      end
      def obj_to_xml(obj,xml)
        obj.send(:"#{@attrname}").fill_into_rexml(@path.first(xml,true))
      end
    end

    class BooleanNode < Node
      def initialize(owner,attrname,path,true_value,false_value)
        super(owner)
        @attrname = attrname; @path = XML::XPath.new(path)
        @true_value = true_value; @false_value = false_value
      end
      def xml_to_obj(obj,xml)
        obj.send :"#{@attrname}=", @path.first(xml)==@true_value
      end
      def obj_to_xml(obj,xml)
        @path.first(xml,true).text = obj.send(:"#{@attrname}")? @true_value : @false_value
      end
    end

    class ArrayNode < Node
      def initialize(owner,attrname,klass,path,path2=nil)
	super(owner)
	if path2
	  do_initialize(attrname,klass,path,path2)
	else
	  do_initialize(attrname,klass,"",path)
	end
      end
      def do_initialize(attrname,klass,base_path,per_arrelement_path)
        @attrname = attrname; @klass = klass;
	per_arrelement_path=per_arrelement_path[1..-1] if per_arrelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_arrelement_path = XML::XPath.new(per_arrelement_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_arrelement_path)
      end
      def xml_to_obj(obj,xml)
        arr = obj.send :"#{@attrname}=", []
        @reader_path.all(xml).each do |elt|
          arr << @klass.load_from_rexml(elt)
        end
      end
      def obj_to_xml(obj,xml)
	base_elt = @base_path.first(xml,true)
	obj.send(:"#{@attrname}").each do |arr_elt|
	  arr_elt.fill_into_rexml(@per_arrelement_path.create_new(base_elt))
	end
      end
    end

    class HashNode < Node
      def initialize(owner,attrname,klass,path1,path2,path3=nil)
        super(owner)
        if path3
          do_initialize(attrname,klass,path1,path2,path3)
        else
          do_initialize(attrname,klass,"",path1,path2)
        end
      end
      def do_initialize(attrname,klass,base_path,per_hashelement_path,key_path)
        @attrname = attrname; @klass = klass;
	per_hashelement_path=per_hashelement_path[1..-1] if per_hashelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_hashelement_path = XML::XPath.new(per_hashelement_path)
	@key_path = XML::XPath.new(key_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_hashelement_path)
      end
      def xml_to_obj(obj,xml)
        hash = obj.send :"#{@attrname}=", {}
        @reader_path.all(xml).each do |elt|
          key = @key_path.first(elt).text
          value = @klass.load_from_rexml(elt)
          hash[key] = value
        end
      end
      def obj_to_xml(obj,xml)
	base_elt = @base_path.first(xml,true)
	obj.send(:"#{@attrname}").each_pair do |k,v|
          elt = @per_hashelement_path.create_new(base_elt)
	  v.fill_into_rexml(elt)
          @key_path.first(elt,true).text = k
	end
      end
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

      attr_accessor :nodes

      def xmlmapping_init
        @nodes = []
      end


      def text_node(attrname,path)
        TextNode.new(self,attrname,path)
        add_accessor attrname
      end

      def array_node(attrname,klass,path,path2=nil)
        ArrayNode.new(self,attrname,klass,path,path2)
        add_accessor attrname
      end

      def hash_node(attrname,klass,path1,path2,path3=nil)
        HashNode.new(self,attrname,klass,path1,path2,path3)
        add_accessor attrname
      end

      def object_node(attrname,klass,path)
        ObjectNode.new(self,attrname,klass,path)
        add_accessor attrname
      end

      def int_node(attrname,path,opts={})
        IntNode.new(self,attrname,path,opts)
        add_accessor attrname
      end

      def boolean_node(attrname,path,true_value,false_value)
        BooleanNode.new(self,attrname,path,true_value,false_value)
        add_accessor attrname
      end

      def comma_separated_strings_node(*args)
        #TODO
      end

      def boolean_presence_node(*args)
        #TODO
      end
    end

  end

end
