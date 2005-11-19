class String
  def self.load_from_xml(xml, options={:mapping=>:_default})
    xml.text
  end

  def fill_into_xml(xml, options={:mapping=>:_default})
    xml.text = self
  end

  def text
    self
  end
end


class Numeric
  def self.load_from_xml(xml, options={:mapping=>:_default})
    begin
      Integer(xml.text)
    rescue ArgumentError
      Float(xml.text)
    end
  end

  def fill_into_xml(xml, options={:mapping=>:_default})
    xml.text = self.to_s
  end

  def text
    self.to_s
  end
end
