# xpath.rb -- XPath implementation for Ruby, including write access
#  Copyright (C) 2004,2005 Olaf Klischat

require 'rexml/document'

module XML

  class XXPathError < RuntimeError
  end

  # Instances of this class hold (in a pre-compiled form) an XPath
  # pattern. You call instance methods like +each+, +first+, +all+,
  # <tt>create_new</tt> on instances of this class to apply the
  # pattern to REXML elements.
  class XXPath

    # create and compile a new XPath. _xpathstr_ is the string
    # representation (XPath pattern) of the path
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


    # loop over all sub-nodes of _node_ that match this XPath.
    def each(node,options={},&block)
      all(node,options).each(&block)
    end

    # the first sub-node of _node_ that matches this XPath. If nothing
    # matches, raise XXPathError unless :allow_nil=>true was provided.
    #
    # If :ensure_created=>true is provided, first() ensures that a
    # match exists in _node_, creating one if none existed before.
    #
    # <tt>path.first(node,:create_new=>true)</tt> is equivalent
    # to <tt>path.create_new(node)</tt>.
    def first(node,options={})
      a=all(node,options)
      if a.empty?
        if options[:allow_nil]
          nil
        else
          raise XXPathError, "path not found: #{@xpathstr}"
        end
      else
        a[0]
      end
    end

    # Return an Enumerable with all sub-nodes of _node_ that match
    # this XPath. Returns an empty Enumerable if no match was found.
    #
    # If :ensure_created=>true is provided, all() ensures that a match
    # exists in _node_, creating one (and returning it as the sole
    # element of the returned enumerable) if none existed before.
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

    # create a completely new match of this XPath in
    # <i>base_node</i>. "Completely new" means that a new node will be
    # created for each path element, even if a matching node already
    # existed in <i>base_node</i>.
    #
    # <tt>path.create_new(node)</tt> is equivalent to
    # <tt>path.first(node,:create_new=>true)</tt>.
    def create_new(base_node)
      first(base_node,:create_new=>true)
    end


    module Accessors  #:nodoc:

      # we need a boolean "unspecified?" attribute for XML nodes --
      # paths like "*" oder (somewhen) "foo|bar" create "unspecified"
      # nodes that the user must then "specify" by setting their text
      # etc. (or manually setting unspecified=false)
      #
      # This is mixed into the REXML::Element and
      # XML::XXPath::Accessors::Attribute classes.
      module UnspecifiednessSupport

        def unspecified?
          @xml_xpath_unspecified ||= false
        end

        def unspecified=(x)
          @xml_xpath_unspecified = x
        end

        def self.included(mod)
          mod.module_eval <<-EOS
            alias_method :_text_orig, :text
            alias_method :_textis_orig, :text=
            def text
              # we're suffering from the "fragile base class"
              # phenomenon here -- we don't know whether the
              # implementation of the class we get mixed into always
              # calls text (instead of just accessing @text or so)
              if unspecified?
                "[UNSPECIFIED]"
              else
                _text_orig
              end
            end
            def text=(x)
              _textis_orig(x)
              self.unspecified=false
            end

            alias_method :_nameis_orig, :name=
            def name=(x)
              _nameis_orig(x)
              self.unspecified=false
            end
          EOS
        end

      end

      class REXML::Element              #:nodoc:
        include UnspecifiednessSupport
      end

      # attribute node, half-way compatible
      # with REXML's Element.
      # REXML doesn't provide one...
      #
      # The all/first calls return instances of this class if they
      # matched an attribute node.
      class Attribute
        attr_reader :parent, :name
        attr_writer :name

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

        # the value of the attribute.
        def text
          parent.attributes[@name]
        end

        def text=(x)
          parent.attributes[@name] = x
        end

        def ==(other)
          other.kind_of?(Attribute) and other.parent==parent and other.name==name
        end

        include UnspecifiednessSupport
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
        if create_new
          newnode = node.elements.add(name)
        else
          newnode = subnodes_by_name_singlesrc(node,name)[0]
          if not(newnode) or newnode.attributes[attr_name]
            newnode = node.elements.add(name)
          end
        end
        newnode.attributes[attr_name]=attr_value
        newnode
      end

      def self.create_subnode_by_name_and_index(node,create_new,name,index)
        name_matches = subnodes_by_name_singlesrc(node,name)
        if create_new and (name_matches.size >= index)
          raise XXPathError, "XPath (#{@xpathstr}): #{name}[#{index}]: create_new and element already exists"
        end
        newnode = name_matches[0]
        (index-name_matches.size).times do
          newnode = node.elements.add name
        end
        newnode
      end

      def self.create_subnode_by_attr_name(node,create_new,name)
        if create_new and node.attributes[name]
          raise XXPathError, "XPath (#{@xpathstr}): @#{name}: create_new and attribute already exists"
        end
        Attribute.new(node,name,true)
      end

      def self.create_subnode_by_all(node,create_new)
        node = node.elements.add
        node.unspecified = true
        node
      end
    end
  end

end
