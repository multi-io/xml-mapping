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



    def self.add_node_class(c)
      meth_name = c.name.split('::')[-1].gsub(/^(.)/){$1.downcase}.gsub(/(.)([A-Z])/){$1+"_"+$2.downcase}
      ClassMethods.module_eval <<-EOS
        def #{meth_name}(attrname,*args)
          #{c.name}.new(self,attrname,*args)
          add_accessor attrname
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

      attr_accessor :nodes

      def xmlmapping_init
        @nodes = []
      end

    end

  end

end
