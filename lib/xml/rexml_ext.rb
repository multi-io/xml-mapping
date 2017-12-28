# xxpath -- XPath implementation for Ruby, including write access
#  Copyright (C) 2004-2010 Olaf Klischat

require 'rexml/document'

module XML

  class XXPath
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

        def self.append_features(base)
          return if base.included_modules.include? self # avoid aliasing methods more than once
                                                        # (would lead to infinite recursion)
          super
          base.module_eval <<-EOS
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

      # attribute node, more or less call-compatible with REXML's
      # Element.  REXML's Attribute class doesn't provide this...
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
    end

  end

end






class REXML::Parent
  def each_on_axis_child
    if respond_to? :attributes
      attributes.each_key do |name|
        yield XML::XXPath::Accessors::Attribute.new(self, name, false)
      end
    end
    each_child do |c|
      yield c
    end
  end

  def each_on_axis_descendant(&block)
    each_on_axis_child do |c|
      block.call c
      if REXML::Parent===c
        c.each_on_axis_descendant(&block)
      end
    end
  end

  def each_on_axis_self
    yield self
  end

  def each_on_axis(axis, &block)
    send :"each_on_axis_#{axis}", &block
  end
end


## hotfix for REXML bug #128 -- see http://trac.germane-software.com/rexml/ticket/128
#   a working Element#write is required by several tests and
#   documentation code snippets
begin
  # temporarily suppress warnings
  class <<Kernel
    alias_method :old_warn, :warn
    def warn(*args)
    end
  end
  begin
    # detect bug
    REXML::Element.new.write("",2)
  ensure
    # unsuppress
    class <<Kernel
      alias_method :warn, :old_warn
    end
  end
rescue NameError
  # bug is present -- fix it. I use Element#write in numerous tests and rdoc
  #  inline code snippets. TODO: switch to REXML::Formatters there sometime.
  class REXML::Element
    def write(output=$stdout, indent=-1, transitive=false, ie_hack=false)
      Kernel.warn("#{self.class.name}.write is deprecated.  See REXML::Formatters")
      formatter = if indent > -1
                    if transitive
                      require "rexml/formatters/transitive"
                      REXML::Formatters::Transitive.new( indent, ie_hack )
                    else
                      REXML::Formatters::Pretty.new( indent, ie_hack )
                    end
                  else
                    REXML::Formatters::Default.new( ie_hack )
                  end
      formatter.write( self, output )
    end
  end
end
