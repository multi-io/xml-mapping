# xxpath -- XPath implementation for Ruby, including write access
#  Copyright (C) 2004-2010 Olaf Klischat

require File.dirname(__FILE__) + "/xxpath"

module XML

  # set of convenience wrappers around XML::XPath's instance methods,
  # for people who frequently use XML::XPath directly. This module is
  # included into the REXML node classes and adds methods to them that
  # enable you to write a call like
  #
  #   path.first(xml_element)
  # 
  # as the more pleasant-looking variant
  #
  #   xml_element.first_xpath(path)
  #
  # with the added bonus that _path_ may not only be an XML::XXPath
  # instance, but also just a String containing the XPath expression.
  #
  # Please note that the names of all the added methods are suffixed
  # with "_xpath" to avoid name clashes with REXML methods. Please
  # note also that this was changed recently, so older versions of
  # xml-mapping (version < 0.9) used method names without _xpath
  # appended and thus would be incompatible with this one here.
  #
  # As a special convenience, if you're using an older version of
  # REXML that doesn't have the new methods yet, methods without
  # _xpath in their names will also (additionally) be added to the
  # REXML classes. This will enable code that relied on the old names
  # to keep on working as long as REXML isn't updated, at which point
  # that code will fail and must be changed to used the methods
  # suffixed with _xpath.
  module XXPathMethods
    # see XML::XXPath#each
    def each_xpath(path,options={},&block)
      to_xxpath(path).each self, options, &block
    end

    # see XML::XXPath#first
    def first_xpath(path,options={})
      to_xxpath(path).first self, options
    end

    # see XML::XXPath#all
    def all_xpath(path,options={})
      to_xxpath(path).all self, options
    end

    # see XML::XXPath#create_new
    def create_new_xpath(path)
      to_xxpath(path).create_new self
    end

    unless REXML::Element.new.respond_to? :first

      # see XML::XXPath#first
      def first_xpath(path,options={})
        to_xxpath(path).first self, options
      end

      # see XML::XXPath#all
      def all_xpath(path,options={})
        to_xxpath(path).all self, options
      end

      # see XML::XXPath#create_new
      def create_new_xpath(path)
        to_xxpath(path).create_new self
      end
      
    end

    def to_xxpath(path)
      if String===path
        XXPath.new path
      else
        path
      end
    end
  end

end


module REXML
  class Child    # mix into nearly every REXML class -- maybe this is a bit too brutal
    include XML::XXPathMethods
  end
end


class XML::XXPath::Accessors::Attribute
  include XML::XXPathMethods
end
