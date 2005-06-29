#:invisible:
$:.unshift "../lib" #<=
#:visible:
require 'xml/xpath'

d=REXML::Document.new <<EOS
  <foo>
    <bar/>
    <bar/>
  </foo>
EOS


rootelt=d.root


XML::XPath.new("*").all(rootelt)#<=
### ok

XML::XPath.new("bar/*").first(rootelt, :allow_nil=>true)#<=
### ok, nothing there

### the same call with :ensure_created=>true
newelt = XML::XPath.new("bar/*").first(rootelt, :ensure_created=>true)#<=

#:invisible_retval:
d.write($stdout,2)#<=

#:visible_retval:
### a new "unspecified" element was created
newelt.unspecified?#<=

### we must modify it to "specify" it
newelt.name="new-one"
newelt.text="hello!"
newelt.unspecified?#<=

#:invisible_retval:
d.write($stdout,2)#<=

### you could also set unspecified to false explicitly, as in:
newelt.unspecified=true
