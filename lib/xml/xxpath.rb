

module XML

  # incredibly incomplete. Only implements what I need right now.
  class XPath
    def initialize(xpathstr)
      p = proc {|xmls,create,allow_nil| xmls}
      p = proc {|xmls,create,allow_nil|
        Accessors::nodes_by_name(p.call(xmls,create,allow_nil),"bla",create,allow_nil)
      }
      @compiled_proc = p
    end


    def each(xml,create=false,allow_nil=false)
      @compiled_proc.call([xml], create, allow_nil)
    end

    def first(xml,create=false)
    end


    module Accessors
      for things in ['name','name_and_attr','name_and_index'] do
        self.module_eval <<-EOS
          def nodes_by_#{things}(xmls, *args)
            xmls.map{|xml| nodes_by_#{things}_singlesrc(xml,*args)}.flatten
          end
        EOS
      end


      def nodes_by_name_singlesrc(node,name,create,allow_nil)
        
      end

      def nodes_by_name_and_attr_singlesrc(node,name,attr_name,attr_value,create,allow_nil)
      end

      def nodes_by_name_and_index_singlesrc(node,name,index,create,allow_nil)
      end
    end
  end

end
