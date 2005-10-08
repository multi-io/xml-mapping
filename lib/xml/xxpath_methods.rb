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
  #   xml_element.first(path)
  #
  # with the added bonus that _path_ may not only be an XML::XXPath
  # instance, but also just a String containing the XPath expression.
  module XXPathMethods
    # see XML::XXPath#each
    def each_xpath(path,options={},&block)
      # ^^^^ name "each" would clash with REXML::Element#each etc.
      to_xxpath(path).each self, options, &block
    end

    # see XML::XXPath#first
    def first(path,options={})
      to_xxpath(path).first self, options
    end

    # see XML::XXPath#all
    def all(path,options={})
      to_xxpath(path).all self, options
    end

    # see XML::XXPath#create_new
    def create_new(path)
      to_xxpath(path).create_new self
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
