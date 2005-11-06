# xpath.rb -- XPath implementation for Ruby, including write access
#  Copyright (C) 2004,2005 Olaf Klischat

require 'rexml/document'
require 'xml/rexml_ext'
require 'xml/xxpath/steps'

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
      
      xpathstr='/'+xpathstr if xpathstr[0] != ?/

      @creator_procs = [ proc{|node,create_new| node} ]
      @reader_proc = proc {|nodes| nodes}
      
      part=nil; part_expected=true
      xpathstr.split(/(\/+)/)[1..-1].reverse.each do |x|
        if part_expected
          part=x
          part_expected = false
          next
        end
        part_expected = true
        axis = case x
               when '/'
                 :child
               when '//'
                 :descendant
               else
                 raise XXPathError, "XPath (#{xpathstr}): unknown axis: #{x}"
               end
        axis=:self if axis==:child and part=='.'   # TODO: verify

        step = Step.compile(axis,part)
        @creator_procs << step.creator(@creator_procs[-1])
        @reader_proc = step.reader(@reader_proc, @creator_procs[-1])
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

  end

end
