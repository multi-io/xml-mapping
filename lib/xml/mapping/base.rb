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
