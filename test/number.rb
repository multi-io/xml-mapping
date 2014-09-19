require 'xml/mapping'

class Number
  include XML::Mapping

  use_mapping :no_default
  numeric_node :value, 'value'

  use_mapping :with_default
  numeric_node :value, 'value', default_value: 0
end
