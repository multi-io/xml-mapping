class Signature
  include XML::Mapping

  text_node :name, "Name"
  text_node :position, "Position", :optional=>true, :default_value=>"Some Employee"
  time_node :signed_on, "signed-on", :optional=>true, :default_value=>Time.now
end
