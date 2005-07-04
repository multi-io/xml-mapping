#:invisible:
$:.unshift "../lib" #<=
#:visible:
require 'xml/xxpath'

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

XML::XXPath.new("/foo/bar").all(d)#<=

XML::XXPath.new("/bar").all(d)#<=

XML::XXPath.new("/foo/bar").all(d.root)#<=

XML::XXPath.new("/bar").all(d.root)#<=


firstelt = XML::XXPath.new("/foo/bar/first").first(d)#<=

XML::XXPath.new("/first/second").all(firstelt)#<=

XML::XXPath.new("/second").all(firstelt)#<=
