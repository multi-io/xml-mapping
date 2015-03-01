# -*- ruby -*-
# adapted from active_record's Rakefile

$:.unshift "."

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'
require 'rake/packagetask'
require 'rubygems/package_task'
require 'rake/contrib/sshpublisher'

require File.dirname(__FILE__)+"/lib/xml/mapping/version"

FILE_RDOC_MAIN = 'user_manual.md'
FILES_RDOC_EXTRA = [FILE_RDOC_MAIN] + %w{README.md user_manual_xxpath.md TODO.txt doc/xpath_impl_notes.txt}
FILES_RDOC_INCLUDES=`git ls-files examples`.split("\n").map{|f| f.gsub(/.intin.rb$/, '.intout')}


desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new :test do |t|
  t.test_files = ["test/all_tests.rb"]
  t.verbose = true
#  t.loader = :testrb
end

# runs tests only if sources have changed since last succesful run of
# tests
file "test_run" => FileList.new('lib/**/*.rb','test/**/*.rb') do
  Task[:test].invoke
  touch "test_run"
end



RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = "XML::Mapping -- Simple, extensible Ruby-to-XML (and back) mapper"
  rdoc.options += %w{--line-numbers --include examples}
  rdoc.main = FILE_RDOC_MAIN
  rdoc.rdoc_files.include(*FILES_RDOC_EXTRA)
  rdoc.rdoc_files.include('lib/**/*.rb')

  task :rdoc => (FileList.new("examples/**/*.rb") + FILES_RDOC_INCLUDES)
end


## need to process :include: statements manually so we can
## have the resulting markdown in the gem
### can't use a rule (recursion issues)
%w{user_manual.md user_manual_xxpath.md}.each do |out_name|
  in_name = "#{File.basename(out_name,'.md')}.in.md"
  CLEAN << out_name
  file out_name => in_name do
    begin
      File.open(out_name, "w") do |fout|
        File.open(in_name, "r") do |fin|
          fin.each_line do |l|
            if m=l.match(/:include: (.*)/)
              File.open("examples/#{m[1]}") do |fincluded|
                fincluded.each_line do |linc|
                  fout.puts "    #{linc}"
                end
              end
            else
              fout.write l
            end
          end
        end
      end
    rescue Exception
      File.delete out_name
      raise
    end
  end
end


#rule '.intout' => ['.intin.rb', *FileList.new("lib/**/*.rb")] do |task|  # doesn't work -- see below
rule '.intout' => ['.intin.rb'] do |task|
  this_file_re = Regexp.compile(Regexp.quote(__FILE__))
  b = binding
  visible=true; visible_retval=true; handle_exceptions=false
  old_stdout = $stdout
  old_wd = Dir.pwd
  begin
    File.open(task.name,"w") do |fout|
      $stdout = fout
      File.open(task.source,"r") do |fin|
        Dir.chdir File.dirname(task.name)
        fin.read.split("#<=\n").each do |snippet|

          snippet.scan(/^#:(.*?):$/) do |switches|
            case switches[0]
            when "visible"
              visible=true
            when "invisible"
              visible=false
            when "visible_retval"
              visible_retval=true
            when "invisible_retval"
              visible_retval=false
            when "handle_exceptions"
              handle_exceptions=true
            when "no_exceptions"
              handle_exceptions=false
            end
          end
          snippet.gsub!(/^#:.*?:(?:\n|\z)/,'')

          print "#{snippet}\n" if visible
          exc_handled = false
          value = begin
                    eval(snippet,b)
                  rescue Exception
                    raise unless handle_exceptions
                    exc_handled = true
                    if visible
                      print "#{$!.class}: #{$!}\n"
                      for m in $@
                        break if m=~this_file_re
                        print "\tfrom #{m}\n"
                      end
                    end
                  end
          if visible and visible_retval and not exc_handled
            print "=> #{value.inspect}\n"
          end
        end
      end
    end
  rescue Exception
    $stdout = old_stdout
    Dir.chdir old_wd
    File.delete task.name
    raise
  ensure
    $stdout = old_stdout
    Dir.chdir old_wd
  end
end

# have to add additional prerequisites manually because it appears
# that rules can only define a single prerequisite :-\
FILES_RDOC_INCLUDES.select{|f|f=~/.intout$/}.each do |f|
  CLEAN << f
  file f => FileList.new("lib/**/*.rb")
  file f => FileList.new("examples/**/*.rb")
end

file 'examples/company_usage.intout' => ['examples/company.xml']
file 'examples/documents_folders_usage.intout' => ['examples/documents_folders.xml']
file 'examples/order_signature_enhanced_usage.intout' => ['examples/order_signature_enhanced.xml']
file 'examples/order_usage.intout' => ['examples/order.xml']
file 'examples/stringarray_usage.intout' => ['examples/stringarray.xml']


spec = Gem::Specification.new do |s|
  s.name = 'xml-mapping'
  s.version = XML::Mapping::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "XML-Object mapper for Ruby"
  s.description =
    "An easy to use, extensible library for semi-automatically mapping Ruby objects to XML and back. Includes an XPath interpreter."
  s.files += FILES_RDOC_EXTRA
  s.files += FILES_RDOC_INCLUDES
  s.files += `git ls-files lib test`.split("\n")
  s.files += %w{LICENSE Rakefile}
  s.extra_rdoc_files = FILES_RDOC_EXTRA
  s.rdoc_options += %w{--include examples}
  s.require_path = 'lib'
  s.add_development_dependency 'rake', '~> 0'
  s.test_file = 'test/all_tests.rb'
  s.author = 'Olaf Klischat'
  s.email = 'olaf.klischat@gmail.com'
  s.homepage = "https://github.com/multi-io/xml-mapping"
  s.rubyforge_project = "xml-mapping"
  s.licenses = ['Apache-2.0']
end



Gem::PackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end



require 'tmpdir'

def system_checked(*args)
  system(*args) or raise "failed to run: #{args.inspect}"
end

desc "updates gh-pages branch in the git with the latest rdoc"
task :ghpublish => [:rdoc] do
  revision = `git rev-parse HEAD`.chomp
  Dir.mktmpdir do |dir|
    # --no-checkout also deletes all files in the target's index
    system_checked("git clone --branch gh-pages --no-checkout . #{dir}")
    cp_r FileList.new('doc/api/*'), dir
    system_checked("cd #{dir} && git add . && git commit -m 'upgrade to #{revision}'")
    system_checked("git fetch #{dir}")
    system_checked("git branch -f gh-pages FETCH_HEAD")
  end
end
