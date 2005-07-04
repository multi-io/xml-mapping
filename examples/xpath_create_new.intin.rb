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

#:invisible_retval:
path1=XML::XXPath.new("/bar/baz[@key='work']")

#:visible_retval:
path1.create_new(rootelt)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### a new element is created for *each* path element, regardless of
### what existed before. So a new "bar" element was added, with a new
### "baz" element inside it

### same call again...
#:visible_retval:
path1.create_new(rootelt)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### same procedure -- new elements added for each path element


#:visible_retval:
## get reference to 1st "baz" element
firstbazelt=XML::XXPath.new("/bar/baz").first(rootelt)#<=

#:invisible_retval:
path2=XML::XXPath.new("@key2")

#:visible_retval:
path2.create_new(firstbazelt)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### ok, new attribute node added

### same call again...
#:visible_retval:
#:handle_exceptions:
path2.create_new(firstbazelt)#<=
#:no_exceptions:
### can't create that path anew again -- an element can't have more
### than one attribute with the same name

#:invisible_retval:
### the document hasn't changed
d.write($stdout,2)#<=



### create_new the same path as in the ensure_created example
#:visible_retval:
baz6elt=XML::XXPath.new("/bar/baz[6]").create_new(rootelt)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### ok, new "bar" element and 6th "baz" element inside it created


#:visible_retval:
#:handle_exceptions:
XML::XXPath.new("baz[6]").create_new(baz6elt.parent)#<=
#:no_exceptions:
#:invisible_retval:
### yep, baz[6] already existed and thus couldn't be created once
### again

### but of course...
#:visible_retval:
XML::XXPath.new("/bar/baz[6]").create_new(rootelt)#<=
#:invisible_retval:
d.write($stdout,2)#<=
### this works because *all* path elements are newly created
