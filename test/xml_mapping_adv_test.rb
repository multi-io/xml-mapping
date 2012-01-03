require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'documents_folders'
require 'bookmarks'
require 'yaml'

class XmlMappingAdvancedTest < Test::Unit::TestCase
  def setup
    XML::Mapping.module_eval <<-EOS
      Classes_by_rootelt_names.clear
    EOS
    Object.send(:remove_const, "Document")
    Object.send(:remove_const, "Folder")

    unless ($".delete "documents_folders.rb")  # works in 1.8 only. In 1.9, $" contains absolute paths.
      $".delete_if{|name| name =~ %r!test/documents_folders.rb$!}
    end
    unless ($".delete "bookmarks.rb")
      $".delete_if{|name| name =~ %r!test/bookmarks.rb$!}
    end
    require 'documents_folders'
    require 'bookmarks'

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

  def test_write_polymorphic_object
    xml = @f.save_to_xml
    assert_equal "folder", xml.name
    assert_equal "home", xml.elements[1].text
    assert_equal "document", xml.elements[2].name
    assert_equal "folder", xml.elements[3].name
    assert_equal "name", xml.elements[3].elements[1].name
    assert_equal "folder", xml.elements[3].elements[2].name
    assert_equal "foo bar baz", xml.elements[3].elements[2].elements[2].elements[2].text

    @f.append "etc", Folder.new
    @f["etc"].append "passwd", Document.new
    @f["etc"]["passwd"].contents = "foo:x:2:2:/bin/sh"
    @f["etc"].append "hosts", Document.new
    @f["etc"]["hosts"].contents = "127.0.0.1 localhost"

    xml = @f.save_to_xml

    xmletc = xml.elements[4]
    assert_equal "etc", xmletc.elements[1].text
    assert_equal "document", xmletc.elements[2].name
    assert_equal "passwd", xmletc.elements[2].elements[1].text
    assert_equal "foo:x:2:2:/bin/sh", xmletc.elements[2].elements[2].text
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

