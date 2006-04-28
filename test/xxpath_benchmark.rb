require File.dirname(__FILE__)+"/benchmark_fixtures"

require "xml/xxpath"

require 'benchmark'
include Benchmark


xxpath_by_name = XML::XXPath.new(@path_by_name)
xxpath_by_idx = XML::XXPath.new(@path_by_idx)    # "bar6"
xxpath_by_idx_idx = XML::XXPath.new(@path_by_idx_idx)    # "bar4-6"
xxpath_by_attr_idx = XML::XXPath.new(@path_by_attr_idx)    # "bar4-6"
xxpath_by_attr = XML::XXPath.new(@path_by_attr)    # "xy"

rootelt = @d.root
foo2elt = rootelt.elements[3]
res1=res2=res3=res4=res5=nil
print "(#{@count} runs)\n"
bmbm(12) do |x|
  x.report("by_name") { @count.times { res1 = xxpath_by_name.first(rootelt) } }
  x.report("by_idx") { @count.times { res2 = xxpath_by_idx.first(rootelt) } }
  x.report("by_idx_idx") { @count.times { res3 = xxpath_by_idx_idx.first(rootelt) } }
  x.report("by_attr_idx") { @count.times { res4 = xxpath_by_attr_idx.first(rootelt) } }
  x.report("xxpath_by_attr") { (@count*4).times { res5 = xxpath_by_attr.first(foo2elt) } }
end


def assert_equal(expected,actual)
  expected==actual or raise "expected: #{expected.inspect}, actual: #{actual.inspect}"
end

assert_equal "bar4-2", res1.text.strip
assert_equal "bar6", res2.text.strip
assert_equal "bar4-6", res3.text.strip
assert_equal "bar4-6", res4.text.strip
assert_equal "xy", res5.text.strip
