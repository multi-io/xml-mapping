class Signature
  include XML::Mapping

  text_node :name, "Name"
  text_node :position, "Position", :default_value=>"Some Employee"
  time_node :signed_on, "signed-on", :default_value=>Time.now
end
