require File.dirname(__FILE__) + '/mapping/base'
require File.dirname(__FILE__) + '/mapping/standard_nodes'

XML::Mapping.add_node_class XML::Mapping::TextNode
XML::Mapping.add_node_class XML::Mapping::IntNode
XML::Mapping.add_node_class XML::Mapping::ObjectNode
XML::Mapping.add_node_class XML::Mapping::BooleanNode
XML::Mapping.add_node_class XML::Mapping::ArrayNode
XML::Mapping.add_node_class XML::Mapping::HashNode
