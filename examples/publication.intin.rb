#:invisible:
$:.unshift "../lib"
require 'xml/mapping'
require 'xml/xxpath_methods'
#<=
#:visible:

class Publication
  include XML::Mapping

  choice_node :if,    '@author', :then, (text_node :author, '@author'),
              :elsif, 'contr',   :then, (array_node :contributors, 'contr', :class=>String)
end

### usage

p1 = Publication.load_from_xml(REXML::Document.new('<publication author="Jim"/>').root)#<=

p2 = Publication.load_from_xml(REXML::Document.new('
<publication>
  <contr>Chris</contr>
  <contr>Mel</contr>
  <contr>Toby</contr>
</publication>').root)#<=

#:invisible:
require 'test/unit/assertions'
include Test::Unit::Assertions

assert_equal "Jim", p1.author
assert_nil p1.contributors

assert_nil p2.author
assert_equal ["Chris", "Mel", "Toby"], p2.contributors

xml1 = p1.save_to_xml
xml2 = p2.save_to_xml

assert_equal p1.author, xml1.first("@author").text
assert_nil xml1.first("contr", :allow_nil=>true)

assert_nil xml2.first("@author", :allow_nil=>true)
assert_equal p2.contributors, xml2.all("contr").map{|elt|elt.text}
#<=
