require 'company'
@xml = REXML::Document.new(File.new("../test/fixtures/company1.xml"))
@c = Company.load_from_xml(@xml.root)
