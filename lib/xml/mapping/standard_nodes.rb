module XML

  module Mapping

    class TextNode < SingleAttributeNode
      def initialize_impl(path)
        @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml)
        @path.first(xml).text
      end
      def set_attr_value(xml, value)
        @path.first(xml,true).text = value
      end
    end

    class IntNode < SingleAttributeNode
      def initialize_impl(path)
        @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml)
        @path.first(xml).text.to_i
      end
      def set_attr_value(xml, value)
        raise RuntimeError, "Not an integer: #{value}" unless Integer===value
        @path.first(xml,true).text = value.to_s
      end
    end

    class ObjectNode < SingleAttributeNode
      def initialize_impl(klass,path)
        @klass = klass; @path = XML::XPath.new(path)
      end
      def extract_attr_value(xml)
        @klass.load_from_rexml(@path.first(xml))
      end
      def set_attr_value(xml, value)
        value.fill_into_rexml(@path.first(xml,true))
      end
    end

    class BooleanNode < SingleAttributeNode
      def initialize_impl(path,true_value,false_value)
        @path = XML::XPath.new(path)
        @true_value = true_value; @false_value = false_value
      end
      def extract_attr_value(xml)
        @path.first(xml).text==@true_value
      end
      def set_attr_value(xml, value)
        @path.first(xml,true).text = value ? @true_value : @false_value
      end
    end

    class ArrayNode < SingleAttributeNode
      def initialize_impl(klass,path,path2=nil)
	if path2
	  do_initialize(klass,path,path2)
	else
	  do_initialize(klass,"",path)
	end
      end
      def do_initialize(klass,base_path,per_arrelement_path)
        @klass = klass;
	per_arrelement_path=per_arrelement_path[1..-1] if per_arrelement_path[0]==?/
	@base_path = XML::XPath.new(base_path)
	@per_arrelement_path = XML::XPath.new(per_arrelement_path)
	@reader_path = XML::XPath.new(base_path+"/"+per_arrelement_path)
      end
      def extract_attr_value(xml)
        result = []
        @reader_path.all(xml).each do |elt|
          result << @klass.load_from_rexml(elt)
        end
        result
      end
      def set_attr_value(xml, value)
	base_elt = @base_path.first(xml,true)
	value.each do |arr_elt|
	  arr_elt.fill_into_rexml(@per_arrelement_path.create_new(base_elt))
	end
      end
    end

    class HashNode < SingleAttributeNode
      def initialize_impl(klass,path1,path2,path3=nil)
        if path3
          do_initialize(klass,path1,path2,path3)
        else
          do_initialize(klass,"",path1,path2)
        end
      end
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
        @reader_path.all(xml).each do |elt|
          key = @key_path.first(elt).text
          value = @klass.load_from_rexml(elt)
          result[key] = value
        end
        result
      end
      def set_attr_value(xml, value)
	base_elt = @base_path.first(xml,true)
	value.each_pair do |k,v|
          elt = @per_hashelement_path.create_new(base_elt)
	  v.fill_into_rexml(elt)
          @key_path.first(elt,true).text = k
	end
      end
    end

  end

end
