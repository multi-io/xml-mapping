require File.dirname(__FILE__)+"/benchmark_fixtures"

require "rexml/xpath"

require 'benchmark'
include Benchmark

rootelt = @d.root
foo2elt = rootelt.elements[3]
res1=res2=res3=res4=res5=nil
print "(#{@count} runs)\n"
bmbm(12) do |x|
  x.report("by_name") { @count.times { res1 = XPath.first(rootelt, @path_by_name) } }
  x.report("by_idx") { @count.times { res2 = XPath.first(rootelt, @path_by_idx) } }
  x.report("by_idx_idx") { @count.times { res3 = XPath.first(rootelt, @path_by_idx_idx) } }
  x.report("by_attr_idx") { @count.times { res4 = XPath.first(rootelt, @path_by_attr_idx) } }
  x.report("xxpath_by_attr") { (@count*4).times { res5 = XPath.first(foo2elt, @path_by_attr) } }
end


def assert_equal(expected,actual)
  expected==actual or raise "expected: #{expected.inspect}, actual: #{actual.inspect}"
end

assert_equal "bar4-2", res1.text.strip
assert_equal "bar6", res2.text.strip
assert_equal "bar4-6", res3.text.strip
assert_equal "bar4-6", res4.text.strip
assert_equal "xy", res5.value.strip
