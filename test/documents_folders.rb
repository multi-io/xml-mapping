require 'xml/mapping'

class Entry
  include XML::Mapping

  text_node :name, "name"
end


class Document <Entry
  text_node :contents, "contents"

  def ==(other)
    Document===other and
      other.name==self.name and
      other.contents==self.contents
  end
end


class Folder <Entry
  array_node :entries, "entries", "*"

  def ==(other)
    Folder===other and
      other.name==self.name and
      other.entries==self.entries
  end
end
