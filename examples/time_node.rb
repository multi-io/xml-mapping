require 'xml/mapping/base'

class TimeNode < XML::Mapping::SingleAttributeNode
  def initialize_impl(path)
    @y_path = XML::XXPath.new(path+"/year")
    @m_path = XML::XXPath.new(path+"/month")
    @d_path = XML::XXPath.new(path+"/day")
  end

  def extract_attr_value(xml)
    y,m,d = default_when_xpath_err{ [@y_path.first(xml).text.to_i,
                                     @m_path.first(xml).text.to_i,
                                     @d_path.first(xml).text.to_i]
                                  }
    Time.local(y,m,d)
  end

  def set_attr_value(xml, value)
    raise "Not a Time: #{value}" unless Time===value
    @y_path.first(xml,:ensure_created=>true).text = value.year
    @m_path.first(xml,:ensure_created=>true).text = value.month
    @d_path.first(xml,:ensure_created=>true).text = value.day
  end
end


XML::Mapping.add_node_class TimeNode
