
module XML

  # incredibly incomplete. Only implements what I need right now.
  class XPath
    def initialize(xpathstr)
      xpathstr=xpathstr[1..-1] if xpathstr[0]==?/
      p = proc {|xmls,create,allow_nil| xmls}
      xpathstr.split('/').each do |part|
        p_prev=p
        p = proc {|xmls,create,allow_nil|
          Accessors.nodes_by_name(p_prev.call(xmls,create,allow_nil),part,create,allow_nil)
        }
      end
      @compiled_proc = p
    end


    def each(xml,create=false,allow_nil=false,&block)
      all(xml,create,allow_nil).each(&block)
    end

    def first(xml,create=false,allow_nil=false)
      all(xml,create,allow_nil)[0]
    end

    def all(xml,create=false,allow_nil=false)
      @compiled_proc.call([xml], create, allow_nil)
    end


    module Accessors
      for things in ['name','name_and_attr','name_and_index'] do
        self.module_eval <<-EOS
          def self.nodes_by_#{things}(xmls, *args)
            xmls.map{|xml| nodes_by_#{things}_singlesrc(xml,*args)}.flatten
          end
        EOS
      end


      def self.nodes_by_name_singlesrc(node,name,create,allow_nil)
        node.elements.select{|elt| elt.name==name}
      end

      def self.nodes_by_name_and_attr_singlesrc(node,name,attr_name,attr_value,create,allow_nil)
      end

      def self.nodes_by_name_and_index_singlesrc(node,name,index,create,allow_nil)
      end
    end
  end

end
