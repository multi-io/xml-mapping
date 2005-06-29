# xml-mapping -- bidirectional Ruby-XML mapper
#  Copyright (C) 2004,2005 Olaf Klischat

$:.unshift(File.dirname(__FILE__)+"/..")

require 'xml/mapping/base'
require 'xml/mapping/standard_nodes'

XML::Mapping.add_node_class XML::Mapping::TextNode
XML::Mapping.add_node_class XML::Mapping::NumericNode
XML::Mapping.add_node_class XML::Mapping::ObjectNode
XML::Mapping.add_node_class XML::Mapping::BooleanNode
XML::Mapping.add_node_class XML::Mapping::ArrayNode
XML::Mapping.add_node_class XML::Mapping::HashNode
