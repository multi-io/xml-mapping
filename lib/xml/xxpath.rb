
module XML

  # incredibly incomplete. Only implements what I need right now.
  class XPath
    def initialize(xpathstr)
      xpathstr=xpathstr[1..-1] if xpathstr[0]==?/
      p = proc {|nodes| nodes}
      xpathstr.split('/').reverse.each do |part|
        p_prev=p
        p = case part
            when /^(.*?)\[@(.*?)='(.*?)'\]$/
              name,attr_name,attr_value = [$1,$2,$3]
              proc {|nodes|
                next_nodes = Accessors.subnodes_by_name_and_attr(nodes,
                                                                 name,attr_name,attr_value)
                if (next_nodes == [])
                  throw :not_found, [nodes,"TODO"]
                else
                  p_prev.call(next_nodes)
                end
              }
            when /^(.*?)\[(.*?)\]$/
              name,index = [$1,$2.to_i]
              proc {|nodes|
                next_nodes = Accessors.subnodes_by_name_and_index(nodes,
                                                                  name,index)
                if (next_nodes == [])
                  throw :not_found, [nodes,"TODO"]
                else
                  p_prev.call(next_nodes)
                end
              }
            when '*'
              proc {|nodes|
                next_nodes = Accessors.subnodes_by_all(nodes)
                if (next_nodes == [])
                  throw :not_found, [nodes,"TODO"]
                else
                  p_prev.call(next_nodes)
                end
              }
            else
              proc {|nodes|
                next_nodes = Accessors.subnodes_by_name(nodes,part)
                if (next_nodes == [])
                  throw :not_found, [nodes,"TODO"]
                else
                  p_prev.call(next_nodes)
                end
              }
            end
      end
      @compiled_proc = p
    end


    def each(node,create=false,allow_nil=false,&block)
      all(xml,create,allow_nil).each(&block)
    end

    def first(node,create=false,allow_nil=false)
      all(xml,create,allow_nil)[0]
    end

    def all(node,create=false,allow_nil=false)
      last_nodes,remaining_path = catch (:not_found) do
        return @compiled_proc.call([node])
      end
      if create
        create(last_nodes[0],remaining_path)
      else
        if allow_nil
          nil
        else
          raise "path not found: ..."
        end
      end
    end


    module Accessors
      for things in %w{name name_and_attr name_and_index all} do
        self.module_eval <<-EOS
          def self.subnodes_by_#{things}(nodes, *args)
            nodes.map{|node| subnodes_by_#{things}_singlesrc(node,*args)}.flatten
          end
        EOS
      end


      def self.subnodes_by_name_singlesrc(node,name)
        node.elements.select{|elt| elt.name==name}
      end

      def self.subnodes_by_name_and_attr_singlesrc(node,name,attr_name,attr_value)
        node.elements.select{|elt| elt.name==name and elt.attributes[attr_name]==attr_value}
      end

      def self.subnodes_by_name_and_index_singlesrc(node,name,index)
        subnodes_by_name_singlesrc(node,name)[index-1]
      end

      def self.subnodes_by_all_singlesrc(node)
        node.elements.to_a
      end
    end
  end

end
