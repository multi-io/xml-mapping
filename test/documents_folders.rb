require 'xml/mapping'

class Entry
  include XML::Mapping

  text_node :name, "name"
end


class Document <Entry
  text_node :contents, "contents"
end


class Folder <Entry
  array_node :entries, "entries", "*"
end
