#:invisible:
$:.unshift "../lib"
require 'stringarray' #<=
#:visible:
ppl=People.load_from_file("stringarray.xml") #<=
ppl.names #<=

ppl.names.concat ["Mary","Arnold"] #<=
#:invisible_retval:
ppl.save_to_xml.write $stdout,2
#<=
