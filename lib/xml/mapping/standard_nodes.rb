module XML

  module Mapping

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
      def initialize(owner,attrname,path,opts={})
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
        obj.send :"#{@attrname}=", @path.first(xml).text==@true_value
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

  end

end
