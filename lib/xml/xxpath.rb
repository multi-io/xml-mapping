
module XML

  # incredibly incomplete. Only implements what I need right now.
  class XPath
    def initialize(xpathstr)
      xpathstr=xpathstr[1..-1] if xpathstr[0]==?/
      p = proc {|xmls,create,allow_nil| xmls}
      xpathstr.split('/').each do |part|
        p_prev=p
        p = case part
            when /^(.*?)\[@(.*?)='(.*?)'\]$/
              name,attr_name,attr_value = [$1,$2,$3]
              proc {|xmls,create,allow_nil|
                Accessors.subnodes_by_name_and_attr(p_prev.call(xmls,create,allow_nil),
                                                    name,attr_name,attr_value, create,allow_nil)
              }
            when /^(.*?)\[(.*?)\]$/
              name,index = [$1,$2.to_i]
              proc {|xmls,create,allow_nil|
                Accessors.subnodes_by_name_and_index(p_prev.call(xmls,create,allow_nil),
                                                     name,index, create,allow_nil)
              }
            when '*'
              proc {|xmls,create,allow_nil|
              Accessors.subnodes_by_all(p_prev.call(xmls,create,allow_nil),
                                        create,allow_nil)
              }
            else
              proc {|xmls,create,allow_nil|
                Accessors.subnodes_by_name(p_prev.call(xmls,create,allow_nil),
                                           part,create,allow_nil)
              }
            end
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
      for things in %w{name name_and_attr name_and_index all} do
        self.module_eval <<-EOS
          def self.subnodes_by_#{things}(nodes, *args)
            nodes.map{|node| subnodes_by_#{things}_singlesrc(node,*args)}.flatten
          end
        EOS
      end


      def self.subnodes_by_name_singlesrc(node,name,create,allow_nil)
        node.elements.select{|elt| elt.name==name}
      end

      def self.subnodes_by_name_and_attr_singlesrc(node,name,attr_name,attr_value,create,allow_nil)
        node.elements.select{|elt| elt.name==name and elt.attributes[attr_name]==attr_value}
      end

      def self.subnodes_by_name_and_index_singlesrc(node,name,index,create,allow_nil)
        subnodes_by_name_singlesrc(node,name,create,allow_nil)[index-1]
      end

      def self.subnodes_by_all_singlesrc(node,create,allow_nil)
        node.elements.to_a
      end
    end
  end

end
