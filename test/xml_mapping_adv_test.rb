require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'documents_folders'
require 'yaml'

class XmlMappingAdvancedTest < Test::Unit::TestCase
  def setup
    @xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/documents_folders2.xml"))
    @f = XML::Mapping.load_object_from_xml(@xml.root)
  end

  def test_read_polymorphic_object
    assert_equal YAML::load(<<-EOS), @f
      --- !ruby/object:Folder 
      entries: 
        - !ruby/object:Document 
          contents: " inhale, exhale"
          name: plan
        - !ruby/object:Folder 
          entries: 
            - !ruby/object:Folder 
              entries: 
                - !ruby/object:Document 
                  contents: foo bar baz
                  name: README
              name: xml-mapping
          name: work
      name: home
    EOS
  end

end

