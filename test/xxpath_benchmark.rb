require File.dirname(__FILE__)+"/tests_init"

require "rexml/document"
require "xml/xxpath"
require 'benchmark'

include Benchmark
include REXML

d = Document.new <<-EOS
<bla rootkey='rootkeyval'>
  <foo>x</foo>
  <bar>bar1</bar>
  <foo key='xy'>
    y
    <u/>
    <bar barkey='hello'>
      bar2
    </bar>
    <quux barkey='goodbye'>
      quux1
    </quux>
    <bar>
      bar3
    </bar>
    <bar barkey='subtree'>
      bar4
      <bar>
        bar4-1
      </bar>
      <foo>
        z
        <bar>
          bar4-2
        </bar>
        hello
        <bar>
          bar4-3
        </bar>
      </foo>
      <bar>
        bar4-4
      </bar>
      <bar>
        bar4-5
      </bar>
      <quux barkey='hello'>
        bar4-quux1
      </quux>
      <bar>
        bar4-6
      </bar>
      <bar>
        bar4-7
      </bar>
    </bar>
    <quux barkey='hello'>
      quux2
    </quux>
    This buffer is for notes you don't want to save, and for Lisp
    evaluation.  If you want to create a file, first visit that file
    with C-x C-f, then enter the text in that file's own buffer.
    <bar>
      bar5
    </bar>
    <bar>
      bar6
    </bar>
    <quux>
      quux3
    </quux>
    <quux barkey='hello'>
      quux4
    </quux>
    <bar>
      bar7
    </bar>
    <bar>
      bar8
    </bar>
    <bar>
      bar9
    </bar>
  </foo>
</bla>
EOS


path_by_name = XML::XXPath.new("foo/bar/foo/bar")
path_by_idx = XML::XXPath.new("foo/bar[5]")    # "bar6"
path_by_idx_idx = XML::XXPath.new("foo/bar[3]/bar[4]")    # "bar4-6"
path_by_attr_idx = XML::XXPath.new("foo/bar[@barkey='subtree']/bar[4]")    # "bar4-6"
path_by_attr = XML::XXPath.new("@key")    # "xy"

rootelt = d.root
foo2elt = rootelt.elements[3]
res1=res2=res3=res4=res5=nil
count=500
print "(#{count} runs)\n"
bmbm(12) do |x|
  x.report("by_name") { count.times { res1 = path_by_name.first(rootelt) } }
  x.report("by_idx") { count.times { res2 = path_by_idx.first(rootelt) } }
  x.report("by_idx_idx") { count.times { res3 = path_by_idx_idx.first(rootelt) } }
  x.report("by_attr_idx") { count.times { res4 = path_by_attr_idx.first(rootelt) } }
  x.report("path_by_attr") { (count*4).times { res5 = path_by_attr.first(foo2elt) } }
end


def assert_equal(expected,actual)
  expected==actual or raise "expected: #{expected.inspect}, actual: #{actual.inspect}"
end

assert_equal "bar4-2", res1.text.strip
assert_equal "bar6", res2.text.strip
assert_equal "bar4-6", res3.text.strip
assert_equal "bar4-6", res4.text.strip
assert_equal "xy", res5.text.strip
