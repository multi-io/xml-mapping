
module XML

  class XPathError < RuntimeError
  end

  # incredibly incomplete. Only implements what I need right now.
  class XPath
    def initialize(xpathstr)
      @xpathstr = xpathstr  # for error messages

      xpathstr=xpathstr[1..-1] if xpathstr[0]==?/

      # TODO: avoid code duplications
      #    maybe: build & create the procs using eval

      @creator_procs = [ proc{|node,create_new| node} ]
      @reader_proc = proc {|nodes| nodes}
      xpathstr.split('/').reverse.each do |part|
        prev_creator = @creator_procs[-1]
        prev_reader = @reader_proc
        case part
        when /^(.*?)\[@(.*?)='(.*?)'\]$/
          name,attr_name,attr_value = [$1,$2,$3]
          @creator_procs << curr_creator = proc {|node,create_new|
            prev_creator.call(Accessors.create_subnode_by_name_and_attr(node,create_new,
                                                                        name,attr_name,attr_value),
                              create_new)
          }
          @reader_proc = proc {|nodes|
            next_nodes = Accessors.subnodes_by_name_and_attr(nodes,
                                                             name,attr_name,attr_value)
            if (next_nodes == [])
              throw :not_found, [nodes,curr_creator]
            else
              prev_reader.call(next_nodes)
            end
          }
        when /^(.*?)\[(.*?)\]$/
          name,index = [$1,$2.to_i]
          @creator_procs << curr_creator = proc {|node,create_new|
            prev_creator.call(Accessors.create_subnode_by_name_and_index(node,create_new,
                                                                         name,index),
                              create_new)
          }
          @reader_proc = proc {|nodes|
            next_nodes = Accessors.subnodes_by_name_and_index(nodes,
                                                              name,index)
            if (next_nodes == [])
              throw :not_found, [nodes,curr_creator]
            else
              prev_reader.call(next_nodes)
            end
          }
        when /^@(.*)$/
          name = $1
          @creator_procs << curr_creator = proc {|node,create_new|
            prev_creator.call(Accessors.create_subnode_by_attr_name(node,create_new,name),
                              create_new)
          }
          @reader_proc = proc {|nodes|
            next_nodes = Accessors.subnodes_by_attr_name(nodes,name)
            if (next_nodes == [])
              throw :not_found, [nodes,curr_creator]
            else
              prev_reader.call(next_nodes)
            end
          }
        when '*'
          @creator_procs << curr_creator = proc {|node,create_new|
            prev_creator.call(Accessors.create_subnode_by_all(node,create_new),
                              create_new)
          }
          @reader_proc = proc {|nodes|
            next_nodes = Accessors.subnodes_by_all(nodes)
            if (next_nodes == [])
              throw :not_found, [nodes,curr_creator]
            else
              prev_reader.call(next_nodes)
            end
          }
        else
          name = part
          @creator_procs << curr_creator = proc {|node,create_new|
            prev_creator.call(Accessors.create_subnode_by_name(node,create_new,name),
                              create_new)
          }
          @reader_proc = proc {|nodes|
            next_nodes = Accessors.subnodes_by_name(nodes,name)
            if (next_nodes == [])
              throw :not_found, [nodes,curr_creator]
            else
              prev_reader.call(next_nodes)
            end
          }
        end
      end
    end


    def each(node,options={},&block)
      all(node,options).each(&block)
    end

    def first(node,options={})
      a=all(node,options)
      if a.empty?
        if options[:allow_nil]
          nil
        else
          raise XPathError, "path not found: #{@xpathstr}"
        end
      else
        a[0]
      end
    end

    def all(node,options={})
      raise "options not a hash" unless Hash===options
      if options[:create_new]
        return [ @creator_procs[-1].call(node,true) ]
      else
        last_nodes,rest_creator = catch(:not_found) do
          return @reader_proc.call([node])
        end
        if options[:ensure_created]
          [ rest_creator.call(last_nodes[0],false) ]
        else
          []
        end
      end
    end

    # convenience method
    def create_new(base_node)
      first(base_node,:create_new=>true)
    end


    module Accessors

      # attribute node, half-way compatible
      #  with REXML's Element.
      # REXML doesn't provide one...
      class Attribute
        attr_reader :parent, :name

        def initialize(parent,name)
          @parent,@name = parent,name
        end

        def self.new(parent,name,create)
          if parent.attributes[name]
            super(parent,name)
          else
            if create
              parent.attributes[name] = "[unset]"
              super(parent,name)
            else
              nil
            end
          end
        end

        def text
          parent.attributes[name]
        end

        def text=(x)
          parent.attributes[name] = x
        end

        def ==(other)
          other.kind_of?(Attribute) and other.parent==parent and other.name==name
        end
      end

      # read accessors

      for things in %w{name name_and_attr name_and_index attr_name all} do
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
        index-=1
        byname=subnodes_by_name_singlesrc(node,name)
        if index>=byname.size
          []
        else
          [byname[index]]
        end
      end

      def self.subnodes_by_attr_name_singlesrc(node,name)
        attr=Attribute.new(node,name,false)
        if attr then [attr] else [] end
      end

      def self.subnodes_by_all_singlesrc(node)
        node.elements.to_a
      end


      # write accessors

      #  precondition: unless create_new, we know that a node with
      #    exactly the requested attributes doesn't exist yet (else we
      #    wouldn't have been called)
      def self.create_subnode_by_name(node,create_new,name)
        node.elements.add name
      end

      def self.create_subnode_by_name_and_attr(node,create_new,name,attr_name,attr_value)
        newnode = (not(create_new) and subnodes_by_name_singlesrc(node,name)[0]) or node.elements.add(name)
        newnode.attributes[attr_name]=attr_value
        newnode
      end

      def self.create_subnode_by_name_and_index(node,create_new,name,index)
        name_matches = subnodes_by_name_singlesrc(node,name)
        if create_new and (name_matches.size >= index)
          raise XPathError, "XPath (#{@xpathstr}): #{name}[#{index}]: create_new and element already exists"
        end
        newnode = name_matches[0]
        (index-name_matches.size).times do
          newnode = node.elements.add name
        end
        newnode
      end

      def self.create_subnode_by_attr_name(node,create_new,name)
        if create_new and node.attributes[name]
          raise XPathError, "XPath (#{@xpathstr}): @#{name}: create_new and attribute already exists"
        end
        Attribute.new(node,name,true)
      end

      def self.create_subnode_by_all(node,create_new)
        # TODO: better strategy here?
        #   if this was an array node, for example,
        #    we should just create nothing and return []
        raise XPathError, "don't know how to create '*'" # if node.elements.empty?
      end
    end
  end

end
