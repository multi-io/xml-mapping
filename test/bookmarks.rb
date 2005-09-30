class BMNode
  attr_accessor :name

  def name=(x)
    @name_set="#{x}_set"
    @name=x
  end

  def name
    @name_get="#{@name}_get"
    @name
  end

  attr_reader :name_set, :name_get

  attr_accessor :last_changed

  def ==(other)
    other.name==self.name and
      other.last_changed==self.last_changed
  end

  def initialize
    yield(self) if block_given?
  end
end

class BMFolder < BMNode
  attr_accessor :entries

  def ==(other)
    super(other) and
      self.entries == other.entries
  end
end

class BM < BMNode
  attr_accessor :url
  attr_accessor :refinement

  def ==(other)
    super(other) and
      self.url == other.url and
      self.refinement == other.refinement
  end
end



require 'xml/mapping'

module Mapping1
  class BMFolderMapping < BMFolder
    include XML::Mapping

    root_element_name 'folder1'

    text_node :name, "@name"
    numeric_node :last_changed, "@last-changed", :default_value=>nil

    array_node :entries, "entries1", "*"
  end

  class BMMapping < BM
    include XML::Mapping

    root_element_name 'bookmark1'

    text_node :name, "@bmname"
    numeric_node :last_changed, "@bmlast-changed", :default_value=>nil

    text_node :url, "url"
    object_node :refinement, "refinement", :default_value=>nil
  end
end


module Mapping2
  # TODO
end
