require File.dirname(__FILE__)+"/tests_init"

require "rexml/document"
include REXML

@d = Document.new(File.new(File.dirname(__FILE__) + "/fixtures/benchmark.xml"))

@path_by_name = "foo/bar/foo/bar"
@path_by_idx = "foo/bar[5]"    # "bar6"
@path_by_idx_idx = "foo/bar[3]/bar[4]"    # "bar4-6"
@path_by_attr_idx = "foo/bar[@barkey='subtree']/bar[4]"    # "bar4-6"
@path_by_attr = "@key"    # "xy"

@count=500
