require 'company'
@xml = REXML::Document.new(File.new("../test/fixtures/company1.xml"))
@c = Company.load_from_xml(@xml.root)


# REXML::XPath is missing all()...
def xpathall(path,xml)
  r=[]
  XPath.each(xml,path){|x|r<<x}
  r
end
