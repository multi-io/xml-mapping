#:invisible:
$:.unshift "../lib" #<=
#:visible:
require 'xml/xxpath'

d=REXML::Document.new <<EOS
  <foo>
    <bar>
      <baz key="work">Java</baz>
      <baz key="play">Ruby</baz>
    </bar>
    <bar>
      <baz key="ab">hello</baz>
      <baz key="play">scrabble</baz>
      <baz key="xy">goodbye</baz>
    </bar>
    <more>
      <baz key="play">poker</baz>
    </more>
  </foo>
EOS


####read access
path=XML::XXPath.new("/foo/bar[2]/baz")

## path.all(document) gives all elements matching path in document
path.all(d)#<=

## loop over them
path.each(d){|elt| puts elt.text}#<=

## the first of those
path.first(d)#<=

## no match here (only three "baz" elements)
path2=XML::XXPath.new("/foo/bar[2]/baz[4]")
path2.all(d)#<=

#:handle_exceptions:
## "first" raises XML::XXPathError in such cases...
path2.first(d)#<=
#:no_exceptions:

##...unless we allow nil returns
path2.first(d,:allow_nil=>true)#<=

##attribute nodes can also be returned
keysPath=XML::XXPath.new("/foo/*/*/@key")

keysPath.all(d).map{|attr|attr.text}#<=
