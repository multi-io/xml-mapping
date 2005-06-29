#:invisible:
$:.unshift "../lib" #<=
#:visible:
require 'xml/xpath'

d=REXML::Document.new <<EOS
  <foo>
    <bar x="hello">
      <first>
        <second>pingpong</second>
      </first>
    </bar>
    <bar x="goodbye"/>
  </foo>
EOS

XML::XPath.new("/foo/bar").all(d)#<=

XML::XPath.new("/bar").all(d)#<=

XML::XPath.new("/foo/bar").all(d.root)#<=

XML::XPath.new("/bar").all(d.root)#<=


firstelt = XML::XPath.new("/foo/bar/first").first(d)#<=

XML::XPath.new("/first/second").all(firstelt)#<=

XML::XPath.new("/second").all(firstelt)#<=
