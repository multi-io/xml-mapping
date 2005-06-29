require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'documents_folders'
require 'multiple_mappings'
require 'yaml'

class XmlMappingAdvancedTest < Test::Unit::TestCase
  def setup
    @f_xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/documents_folders2.xml"))
    @f = XML::Mapping.load_object_from_xml(@f_xml.root)

    @bm1_xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/bookmarks1.xml"))
    @bm1 = XML::Mapping.load_object_from_xml(@bm1_xml.root)
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


  def test_read_bookmars1_2
     expected = BMFolder.new{|x|
      x.name = "root"
      x.last_changed = 123
      x.entries = [
        BM.new{|x|  
          x.name="ruby"
          x.last_changed=345
          x.url="http://www.ruby-lang.org"
          x.refinement=nil
        }, 
        BM.new{|x|  
          x.name="RAA"
          x.last_changed=nil
          x.url="http://raa.ruby-lang.org/"
          x.refinement=nil
        },
        BMFolder.new{|x|  
          x.name="news"
          x.last_changed=nil
          x.entries = [
            BM.new{|x|
              x.name="/."
              x.last_changed=233
              x.url="http://www.slashdot.org/"
              x.refinement=nil
            },
            BM.new{|x|
              x.name="groklaw"
              x.last_changed=238
              x.url="http://www.groklaw.net/"
              x.refinement=nil
            }
          ]
        }
      ]
    }
    # need to compare expected==@bm1 because @bm1.== would be the
    # XML::Mapping#== defined in xml_mapping_test.rb ...
    assert_equal expected, @bm1
    assert_equal "root_set", @bm1.name_set
    assert_equal "ruby_set", @bm1.entries[0].name_set
    @bm1.entries[0].name = "foobar"
    assert_equal "foobar_set", @bm1.entries[0].name_set
  end
end

