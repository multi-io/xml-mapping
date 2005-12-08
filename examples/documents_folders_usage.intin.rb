#:invisible:
$:.unshift "../lib"
require 'documents_folders' #<=
#:visible:

root = XML::Mapping.load_object_from_file "documents_folders.xml" #<=
root.name #<=
root.entries #<=

root.append "etc", Folder.new
root["etc"].append "passwd", Document.new
root["etc"]["passwd"].contents = "foo:x:2:2:/bin/sh"
root["etc"].append "hosts", Document.new
root["etc"]["hosts"].contents = "127.0.0.1 localhost"

xml = root.save_to_xml #<=
#:invisible_retval:
xml.write $stdout,2
