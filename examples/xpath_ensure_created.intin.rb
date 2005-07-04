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
  </foo>
EOS


rootelt=d.root

#### ensuring that a specific path exists inside the document

#:visible_retval:
XML::XXPath.new("/bar/baz[@key='work']").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### no change (path existed before)


#:visible_retval:
XML::XXPath.new("/bar/baz[@key='42']").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### path was added

#:visible_retval:
XML::XXPath.new("/bar/baz[@key='42']").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### no change this time

#:visible_retval:
XML::XXPath.new("/bar/baz[@key2='hello']").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### this fit in the 1st "baz" element since
### there was no "key2" attribute there before.

#:visible_retval:
XML::XXPath.new("/bar/baz[2]").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### no change

#:visible_retval:
XML::XXPath.new("/bar/baz[6]/@haha").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### for there to be a 6th "baz" element, there must be 1st..5th "baz" elements

#:visible_retval:
XML::XXPath.new("/bar/baz[6]/@haha").first(rootelt,:ensure_created=>true)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### no change this time
