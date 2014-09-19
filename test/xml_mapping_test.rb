require File.dirname(__FILE__)+"/tests_init"

require 'test/unit'
require 'company'
require 'xml/xxpath_methods'

module XML::Mapping
  def ==(other)
    Marshal.dump(self) == Marshal.dump(other)
  end
end

class XmlMappingTest < Test::Unit::TestCase
  def setup
    # need to undo mapping class definitions that may have been
    # established by other tests (and outlive those tests)

    # this requires some ugly hackery with internal variables
    XML::Mapping.module_eval <<-EOS
      Classes_by_rootelt_names.clear
    EOS
    Object.send(:remove_const, "Company")
    Object.send(:remove_const, "Address")
    Object.send(:remove_const, "Office")
    Object.send(:remove_const, "Customer")
    Object.send(:remove_const, "Thing")
    Object.send(:remove_const, "Names1")
    Object.send(:remove_const, "ReaderTest")
    Object.send(:remove_const, "WriterTest")
    Object.send(:remove_const, "ReaderWriterProcVsLambdaTest")
    unless ($".delete "company.rb") # works in 1.8 only. In 1.9, $" contains absolute paths.
      $".delete_if{|name| name =~ %r!test/company.rb$!}
    end
    $:.unshift File.dirname(__FILE__)  # test/unit may have undone this (see test/unit/collector/dir.rb)
    require 'company'

    @xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/company1.xml"))
    @c = Company.load_from_xml(@xml.root)
  end

  def test_getter_text_node
    assert_equal "bar", @c.ent2
  end

  def test_getter_int_node
    assert_equal 18, @c.offices[1].address.number
  end

  def test_int_node_default_value
    require 'number'
    xml = REXML::Document.new(File.new(File.dirname(__FILE__) + "/fixtures/number.xml"))

    assert_raise RuntimeError, 'No default value for empty numeric value' do
      Number.load_from_xml(xml.root, :mapping => :no_default)
    end

    num = nil
    assert_nothing_raised do
      num = Number.load_from_xml(xml.root, :mapping => :with_default)
    end

    assert_equal 0, num.value
  end

  def test_getter_boolean_node
    path=XML::XXPath.new("offices/office[2]/classified")
    assert_equal(path.first(@xml.root).text == "yes",
                 @c.offices[1].classified)
  end

  def test_getter_hash_node
    assert_equal 4, @c.customers.keys.size
    ["cm", "ernie", "jim", "sad"].zip(@c.customers.keys.sort).each do |exp,ckey|
      assert_equal exp, ckey
      assert_equal exp, @c.customers[ckey].uid
    end
  end


  def test_getter_choice_node
    assert_equal 4, @c.things.size
    assert_equal "name1", @c.things[0].name
    assert_equal "name2", @c.things[1].name
    assert_equal "name3", @c.things[2].name
    assert_equal "name4-elt", @c.things[3].name
  end


  def test_getter_choice_node_multiple_attrs
    d = REXML::Document.new <<-EOS
    <names1>
      <names>
        <name>multi1</name>
        <name>multi2</name>
      </names>
      <name>single</name>
    </names1>
    EOS
    n1 = Names1.load_from_xml d.root
    assert_equal "single", n1.name
    assert_nil n1.names

    d.root.delete_element "name"
    n1 = Names1.load_from_xml d.root
    assert_nil n1.name
    assert_equal ["multi1","multi2"], n1.names
  end


  def test_choice_node_presence
    node = Thing.xml_mapping_nodes[0]
    t = Thing.new
    assert !(node.is_present_in? t)
    t.name = "Mary"
    assert node.is_present_in? t
  end


  def test_getter_array_node
    assert_equal ["pencils", "weapons of mass destruction"],
          @c.offices.map{|o|o.speciality}
  end


  def test_reader
    xml = REXML::Document.new("<test>
                                 <foo>footext</foo>
                                 <foo2>foo2text</foo2>
                                 <foo3>foo3text</foo3>
                                 <bar>bartext</bar>
                              </test>").root
    r = ReaderTest.load_from_xml xml
    assert_equal 'footext', r.foo
    assert_nil r.foo2
    assert_equal 'foo3text', r.foo3
    assert_equal 'bartext', r.bar
    assert_equal [:foo2,:foo3], r.read

    r.foo = 'foonew'
    r.foo2 = 'foo2new'
    r.foo3 = 'foo3new'
    r.bar = 'barnew'
    xml2 = r.save_to_xml
    assert_equal 'foonew', xml2.first_xpath("foo").text
    assert_equal 'foo2new', xml2.first_xpath("foo2").text
    assert_equal 'foo3new', xml2.first_xpath("foo3").text
    assert_equal 'barnew', xml2.first_xpath("bar").text
  end


  def test_writer
    xml = REXML::Document.new("<test>
                                 <foo>footext</foo>
                                 <foo2>foo2text</foo2>
                                 <foo3>foo3text</foo3>
                                 <bar>bartext</bar>
                              </test>").root
    w = WriterTest.load_from_xml xml
    assert_equal 'footext', w.foo
    assert_equal 'foo2text', w.foo2
    assert_equal 'foo3text', w.foo3
    assert_equal 'bartext', w.bar

    w.foo = 'foonew'
    w.foo2 = 'foo2new'
    w.foo3 = 'foo3new'
    w.bar = 'barnew'
    xml2 = w.save_to_xml
    assert_equal 'foonew', xml2.first_xpath("foo").text
    assert_nil xml2.first_xpath("foo2",:allow_nil=>true)
    assert_equal 'foo3new', xml2.first_xpath("foo3").text
    assert_equal 'barnew', xml2.first_xpath("bar").text

    assert_equal %w{dingdong2 dingdong3}, xml2.all_xpath("quux").map{|elt|elt.text}
  end

  def test_reader_writer_proc_vs_lambda
    xml = REXML::Document.new("<test>
                                 <proc_2args>proc_2args_text</proc_2args>
                                 <lambda_2args>lambda_2args_text</lambda_2args>
                                 <proc_3args>proc_3args_text</proc_3args>
                                 <lambda_3args>lambda_3args_text</lambda_3args>
                              </test>").root
    r = ReaderWriterProcVsLambdaTest.load_from_xml xml
    assert_equal [:proc_2args, :proc_3args, :lambda_2args, :lambda_3args], r.read
    assert_nil r.written
    assert_nil r.proc_2args
    assert_nil r.lambda_2args
    assert_equal 'proc_3args_text', r.proc_3args
    assert_equal 'lambda_3args_text', r.lambda_3args

    r.proc_2args = "proc_2args_text_new"
    r.lambda_2args = "lambda_2args_text_new"
    r.proc_3args = "proc_3args_text_new"
    r.lambda_3args = "lambda_3args_text_new"
    xml2 = r.save_to_xml
    assert_equal [:proc_2args, :proc_3args, :lambda_2args, :lambda_3args], r.written
    assert_nil xml2.first_xpath("proc_2args", :allow_nil=>true)
    assert_nil xml2.first_xpath("lambda_2args", :allow_nil=>true)
    assert_equal 'proc_3args_text_new', xml2.first_xpath("proc_3args").text
    assert_equal 'lambda_3args_text_new', xml2.first_xpath("lambda_3args").text
  end

  def test_setter_text_node
    @c.ent2 = "lalala"
    assert_equal "lalala", REXML::XPath.first(@c.save_to_xml, "arrtest/entry[2]").text
  end
  
  
  def test_setter_array_node
    xml=@c.save_to_xml
    assert_equal ["pencils", "weapons of mass destruction"],
          XML::XXPath.new("offices/office/@speciality").all(xml).map{|n|n.text}
  end
  
  
  def test_setter_hash_node
    xml=@c.save_to_xml
    assert_equal @c.customers.keys.sort,
          XML::XXPath.new("customers/customer/@uid").all(@xml.root).map{|n|n.text}.sort
  end
  
  
  def test_setter_boolean_node
    @c.offices[0].classified = !@c.offices[0].classified
    xml=@c.save_to_xml
    assert_equal @c.offices[0].classified,
           XML::XXPath.new("offices/office[1]/classified").first(xml).text == "yes"
  end


  def test_setter_choice_node
    xml=@c.save_to_xml
    thingselts = xml.all_xpath("stuff2/thing")
    assert_equal @c.things.size, thingselts.size
    assert_equal @c.things[0].name, thingselts[0].first_xpath("name").text
    assert_equal @c.things[1].name, thingselts[1].first_xpath("name").text
    assert_equal @c.things[2].name, thingselts[2].first_xpath("name").text
    assert_equal @c.things[3].name, thingselts[3].first_xpath("name").text
  end


  def test_setter_choice_node_multiple_attrs
    n1 = Names1.new
    assert_raises(XML::MappingError) {
      n1.save_to_xml   # no choice present in n1
    }

    n1.names = ["multi1","multi2"]
    xml = n1.save_to_xml
    assert_equal n1.names, xml.all_xpath("names/name").map{|elt|elt.text}
    assert_nil xml.first_xpath("name", :allow_nil=>true)

    n1.name = "foo"
    xml = n1.save_to_xml
    assert_equal [], xml.all_xpath("names/name").map{|elt|elt.text}
    assert_equal n1.name, xml.first_xpath("name", :allow_nil=>true).text
  end


  def test_root_element
    assert_equal @c, XML::Mapping.load_object_from_file(File.dirname(__FILE__) + "/fixtures/company1.xml")
    assert_equal @c, XML::Mapping.load_object_from_xml(@xml.root)

    assert_equal "company", Company.root_element_name
    assert_equal Company, XML::Mapping.class_for_root_elt_name("company")
    xml=@c.save_to_xml
    assert_equal "company", xml.name
    # Company.root_element_name 'my-test'
    Company.class_eval <<-EOS
        root_element_name 'my-test'
    EOS
    assert_equal "my-test", Company.root_element_name
    assert_equal Company, XML::Mapping.class_for_root_elt_name("my-test")
    assert_nil XML::Mapping.class_for_root_elt_name("company")
    xml=@c.save_to_xml
    assert_equal "my-test", xml.name
    assert_equal "office", @c.offices[0].save_to_xml.name

    assert_raises(XML::MappingError) {
      XML::Mapping.load_object_from_xml @xml.root
    }
    @xml.root.name = 'my-test'
    assert_equal @c, XML::Mapping.load_object_from_xml(@xml.root)

    # white-box tests
    #assert_equal [["my-test", {:_default=>Company}]], XML::Mapping::Classes_w_nondefault_rootelt_names.sort
    #assert_equal [["address", {:_default=>Address}],
    #              ["company", {}],
    #              ["customer", {:_default=>Customer}],
    #              ["office", {:_default=>Office}]],
    #      XML::Mapping::Classes_w_default_rootelt_names.sort
  end


  def test_optional_flag
    hamburg_address_path = XML::XXPath.new("offices/office[1]/address")
    baghdad_address_path = XML::XXPath.new("offices/office[2]/address")
    hamburg_zip_path = XML::XXPath.new("offices/office[1]/address/zip")
    baghdad_zip_path = XML::XXPath.new("offices/office[2]/address/zip")

    assert_equal 18282, @c.offices[0].address.zip
    assert_equal 12576, @c.offices[1].address.zip
    xml=@c.save_to_xml
    assert_equal "18282", hamburg_zip_path.first(xml).text
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)
    @c.offices[1].address.zip = 12577
    xml=@c.save_to_xml
    assert_equal "12577", baghdad_zip_path.first(xml).text
    c2 = Company.load_from_xml(xml)
    assert_equal 12577, c2.offices[1].address.zip
    @c.offices[1].address.zip = 12576
    xml=@c.save_to_xml
    assert_nil baghdad_zip_path.first(xml,:allow_nil=>true)

    hamburg_address_path.first(xml).delete_element("zip")
    c3 = Company.load_from_xml(xml)
    assert_equal 12576, c3.offices[0].address.zip
    hamburg_address_path.first(xml).delete_element("city")
    assert_raises(XML::MappingError) {
      Company.load_from_xml(xml)
    }
  end


  def test_optional_flag_nodefault
    hamburg_address_path = XML::XXPath.new("offices/office[1]/address")
    hamburg_street_path = XML::XXPath.new("offices/office[1]/address/street")

    assert_equal hamburg_street_path.first(@xml.root).text,
          @c.offices[0].address.street

    hamburg_address_path.first(@xml.root).delete_element("street")
    c2 = Company.load_from_xml(@xml.root)
    assert_nil c2.offices[0].address.street

    xml2=c2.save_to_xml
    assert_nil hamburg_street_path.first(xml2,:allow_nil=>true)
  end


  def test_default_value_identity_on_initialize
    c = Company.new
    assert_equal ["default"], c.test_default_value_identity
    c.test_default_value_identity << "foo"

    c2 = Company.new
    assert_equal ["default"], c2.test_default_value_identity
  end


  def test_default_value_identity_on_load
    assert_equal ["default"], @c.test_default_value_identity
    @c.test_default_value_identity << "bar"

    c2 = Company.load_from_file(File.dirname(__FILE__) + "/fixtures/company1.xml")
    assert_equal ["default"], c2.test_default_value_identity
  end


  def test_polymorphic_node
    assert_equal 3, @c.stuff.size
    assert_equal 'Saddam Hussein', @c.stuff[0].name
    assert_equal 'Berlin', @c.stuff[1].city
    assert_equal 'weapons of mass destruction', @c.stuff[2].speciality

    @c.stuff[1].city = 'Munich'
    @c.stuff[2].classified = false

    xml2=@c.save_to_xml
    assert_equal 'Munich', xml2.root.elements[5].elements[2].elements[1].text
    assert_equal 'no',     xml2.root.elements[5].elements[3].elements[1].text
  end


  def test_file_io
    require 'tmpdir'
    Dir.mktmpdir do |dir|
      @c.save_to_file "#{dir}/out.xml"
      c2 = Company.load_from_file "#{dir}/out.xml"
      assert_equal @c, c2, 'read back object equals original'

      @c.save_to_file "#{dir}/out_default.xml", :formatter=>REXML::Formatters::Default.new

      assert FileUtils.compare_file("#{dir}/out.xml", "#{dir}/out_default.xml"), 'default formatter is Formatters::Default'
      assert File.open("#{dir}/out_default.xml").readlines.grep(/^\s/).empty?, 'default formatter produces no indentations'

      @c.save_to_file "#{dir}/out_pretty.xml", :formatter=>REXML::Formatters::Pretty.new
      assert not(File.open("#{dir}/out_pretty.xml").readlines.grep(/^\s/).empty?), 'pretty formatter does produce indentations'

      Company.class_eval <<-EOS
        mapping_output_formatter REXML::Formatters::Pretty.new
      EOS

      @c.save_to_file "#{dir}/out2.xml"
      assert FileUtils.compare_file("#{dir}/out2.xml", "#{dir}/out_pretty.xml"), 'default formatter can be changed on a per-class basis'
    end
  end

end
