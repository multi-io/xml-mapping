# xxpath -- XPath implementation for Ruby, including write access
#  Copyright (C) 2004-2006 Olaf Klischat

module XML
  class XXPath

    # base class for XPath "steps". Steps contain an "axis" (e.g.
    # "/", "//", i.e. the "child" resp. "descendants" axis), and
    # a "node matcher" like "foo" or "@bar" or "foo[@bar='baz']", i.e. they
    # match some XML nodes and don't match others (e.g. "foo[@bar='baz']"
    # macthes all XML element nodes named "foo" that contain an attribute
    # with name "bar" and value "baz").
    #
    # Steps can find out whether they match a given XML node
    # (Step#matches?(node)), and they know how to create a matchingnode
    # on a given base node (Step#create_on(node,create_new)).
    class Step #:nodoc:
      def self.inherited(subclass)
        (@subclasses||=[]) << subclass
      end

      # create and return an instance of the right Step subclass for
      # axis _axis_ (:child or :descendant atm.) and node matcher _string_
      def self.compile axis, string
        (@subclasses||=[]).each do |sc|
          obj = sc.compile axis, string
          return obj if obj
        end
        raise XXPathError, "can't compile XPath step: #{string}"
      end

      def initialize axis
        @axis = axis
      end

      # return a proc that takes a list of nodes, finds all sub-nodes
      # that are reachable from one of those nodes via _self_'s axis
      # and match (see below) _self_, and calls _prev_reader_ on them
      # (and returns the result).  When the proc doesn't find any such
      # nodes, it throws <tt>:not_found,
      # [nodes,creator_from_here]</tt>.
      #
      # Needed for compiling whole XPath expressions for reading.
      #
      # <tt>Step</tt> itself provides a generic default implementation
      # which checks whether _self_ matches a given node by calling
      # self.matches?(node). Subclasses must either implement such a
      # _matches?_ method or override _reader_ to provide more
      # specialized implementations for better performance.
      def reader(prev_reader,creator_from_here)
        proc {|nodes|
          next_nodes = []
          nodes.each do |node|
            if node.respond_to? :each_on_axis
              node.each_on_axis(@axis) do |subnode|
                next_nodes << subnode if self.matches?(subnode)
              end
            end
          end
          if (next_nodes.empty?)
            throw :not_found, [nodes,creator_from_here]
          else
            prev_reader.call(next_nodes)
          end
        }
      end

      # return a proc that takes a node, creates a sub-node matching
      # _self_ on it, and then calls _prev_creator_ on that and
      # returns the result.
      #
      # Needed for compiling whole XPath expressions for writing.
      #
      # <tt>Step</tt> itself provides a generic default
      # implementation, subclasses may provide specialized
      # implementations for better performance.
      def creator(prev_creator)
	if @axis==:child or @axis==:self
	  proc {|node,create_new|
	    prev_creator.call(self.create_on(node,create_new),
			      create_new)
	  }
	else
	  proc {|node,create_new|
	    raise XXPathError, "can't create axis: #{@axis}"
	  }
	end
      end
    end


    class AttrStep < Step #:nodoc:
      def self.compile axis, string
        /^(?:\.|self::\*)\[@(.*?)='(.*?)'\]$/ === string or return nil
        self.new axis,$1,$2
      end

      def initialize(axis,attr_name,attr_value)
        super(axis)
        @attr_name,@attr_value = attr_name,attr_value
      end

      def matches? node
        node.is_a?(REXML::Element) and node.attributes[@attr_name]==@attr_value
      end

      def create_on(node,create_new)
        if create_new
          raise XXPathError, "XPath: .[@'#{@attr_name}'='#{@attr_value}']: create_new but context node already exists"
        end
        # TODO: raise if node.attributes[@attr_name] already exists?
        node.attributes[@attr_name]=@attr_value
        node
      end
    end


    class NameAndAttrStep < Step #:nodoc:
      def self.compile axis, string
        /^(.*?)\[@(.*?)='(.*?)'\]$/ === string or return nil
        self.new axis,$1,$2,$3
      end

      def initialize(axis,name,attr_name,attr_value)
        super(axis)
        @name,@attr_name,@attr_value = name,attr_name,attr_value
      end

      def matches? node
        node.is_a?(REXML::Element) and node.name==@name and node.attributes[@attr_name]==@attr_value
      end

      def create_on(node,create_new)
        if create_new
          newnode = node.elements.add(@name)
        else
          newnode = node.elements.select{|elt| elt.name==@name and not(elt.attributes[@attr_name])}[0]
          if not(newnode)
            newnode = node.elements.add(@name)
          end
        end
        newnode.attributes[@attr_name]=@attr_value
        newnode
      end
    end


    class NameAndIndexStep < Step #:nodoc:
      def self.compile axis, string
        /^(.*?)\[(\d+)\]$/ === string or return nil
        self.new axis,$1,$2.to_i
      end

      def initialize(axis,name,index)
        super(axis)
        @name,@index = name,index
      end

      def matches? node
        raise XXPathError, "can't use #{@name}[#{@index}] on root node" if node.parent.nil?
        node == node.parent.elements.select{|elt| elt.name==@name}[@index-1]
      end

      def create_on(node,create_new)
        name_matches = node.elements.select{|elt| elt.name==@name}
        if create_new and (name_matches.size >= @index)
          raise XXPathError, "XPath: #{@name}[#{@index}]: create_new and element already exists"
        end
        newnode = name_matches[0]
        (@index-name_matches.size).times do
          newnode = node.elements.add @name
        end
        newnode
      end

      def reader(prev_reader,creator_from_here)
        if @axis==:child
          index = @index - 1
          proc {|nodes|
            next_nodes = []
            nodes.each do |node|
              byname=node.elements.select{|elt| elt.name==@name}
              next_nodes << byname[index] if index<byname.size
            end
            if (next_nodes.empty?)
              throw :not_found, [nodes,creator_from_here]
            else
              prev_reader.call(next_nodes)
            end
          }
        else
          super(prev_reader,creator_from_here)
        end
      end
    end


    class AttrNameStep < Step #:nodoc:
      def self.compile axis, string
        /^@(.*)$/ === string or return nil
        self.new axis,$1
      end

      def initialize(axis,attr_name)
        super(axis)
        @attr_name = attr_name
      end

      def matches? node
        node.class==XML::XXPath::Accessors::Attribute and node.name==@attr_name
      end

      def create_on(node,create_new)
        if create_new and node.attributes[@attr_name]
          raise XXPathError, "XPath (@#{@attr_name}): create_new and attribute already exists"
        end
        XML::XXPath::Accessors::Attribute.new(node,@attr_name,true)
      end

      def reader(prev_reader,creator_from_here)
        if @axis==:child
          proc {|nodes|
            next_nodes = []
            nodes.each do |node|
              attr=XML::XXPath::Accessors::Attribute.new(node,@attr_name,false)
              next_nodes << attr if attr
            end
            if (next_nodes.empty?)
              throw :not_found, [nodes,creator_from_here]
            else
              prev_reader.call(next_nodes)
            end
          }
        else
          super(prev_reader,creator_from_here)
        end
      end
    end


    class AllElementsStep < Step #:nodoc:
      def self.compile axis, string
        '*'==string or return nil
        self.new axis
      end

      def matches? node
        node.is_a? REXML::Element
      end

      def create_on(node,create_new)
        newnode = node.elements.add
        newnode.unspecified = true
        newnode
      end
    end


    class ThisNodeStep < Step #:nodoc:
      def self.compile axis, string
        '.'==string or return nil
        self.new axis
      end

      def matches? node
        true
      end

      def create_on(node,create_new)
        if create_new
          raise XXPathError, "XPath: .: create_new and attribute already exists"
        end
        node
      end
    end


    class AlternativeNamesStep < Step #:nodoc:
      def self.compile axis, string
        if string=~/\|/
          self.new axis, string.split('|')
        else
          nil
        end
      end

      def initialize(axis,names)
        super(axis)
        @names = names
      end

      def matches? node
        node.is_a?(REXML::Element) and @names.inject(false){|prev,name| prev or node.name==name}
      end

      def create_on(node,create_new)
        newnode = node.elements.add
        newnode.unspecified = true
        newnode
      end
    end


    class TextNodesStep < Step #:nodoc:
      def self.compile axis, string
        'text()' == string or return nil
        self.new axis
      end

      def matches? node
        node.is_a? REXML::Text
      end

      def create_on(node,create_new)
        node.add(REXML::Text.new(""))
      end
    end

    class REXML::Text
      # call-compatibility w/ REXML::Element
      alias_method :text, :value
      alias_method :text=, :value=
    end


    class NameStep < Step #:nodoc:
      def self.compile axis, string
        self.new axis,string
      end

      def initialize(axis,name)
        super(axis)
        @name = name
      end

      def matches? node
        node.is_a?(REXML::Element) and node.name==@name
      end

      def create_on(node,create_new)
        node.elements.add @name
      end
    end
  end
end
