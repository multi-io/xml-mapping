# -*- ruby -*-
# adapted from active_record's Rakefile

require 'build_lib/rdoc_ext'

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'build_lib/my_rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'
require 'rake/contrib/sshpublisher'

require File.dirname(__FILE__)+"/lib/xml/mapping/version"


# yeah -- it's just stupid that these are private

class Rake::PackageTask
  public :tgz_file, :zip_file
end

class Rake::GemPackageTask
  public :gem_file
end


FILES_RDOC_EXTRA=%w{README README_XPATH TODO.txt doc/xpath_impl_notes.txt}
FILES_RDOC_INCLUDES=%w{examples/company.xml
                       examples/company.rb
                       examples/company_usage.intout
                       examples/order.xml
                       examples/order.rb
                       examples/order_usage.intout
                       examples/stringarray_usage.intout
                       examples/stringarray.xml
                       examples/documents_folders_usage.intout
                       examples/documents_folders.xml
                       examples/time_node_w_marshallers.intout
                       examples/time_node_w_marshallers.xml
                       examples/time_augm.intout
                       examples/time_augm_loading.intout
                       examples/xpath_usage.intout
                       examples/xpath_ensure_created.intout
                       examples/xpath_create_new.intout
                       examples/xpath_pathological.intout
                       examples/xpath_docvsroot.intout
                       examples/order_signature_enhanced_usage.intout
                       examples/order_signature_enhanced.xml
                       examples/person.intout
                      }


desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new(:test) { |t|
  t.test_files = ["test/all_tests.rb"]
  t.verbose = true
#  t.loader = :testrb
}

# runs tests only if sources have changed since last succesful run of
# tests
file "test_run" => FileList.new('lib/**/*.rb','test/**/*.rb') do
  Task[:test].invoke
  touch "test_run"
end



MyRDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = "XML::Mapping -- Simple, extensible Ruby-to-XML (and back) mapper"
  rdoc.options += %w{--line-numbers --inline-source --accessor cattr_accessor=object --include examples}
  rdoc.rdoc_files.include(*FILES_RDOC_EXTRA)
  rdoc.rdoc_files.include('lib/**/*.rb')

  # additional file dependencies for the rdoc task
  #   this somewhat of a black art because RDocTask doesn't document the
  #   prerequisite of its rdoc task (<rdoc_dir>/index.html)
  file rdoc.rdoc_target => FILES_RDOC_INCLUDES
  file "#{rdoc.rdoc_dir}/index.html" => FileList.new("examples/**/*.rb")
}

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

          snippet.scan(/^#:(.*?):$/) do |(switch,)|
            case switch
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
  s.summary =
    "An easy to use, extensible library for mapping Ruby objects to XML and back. Includes an XPath interpreter."

  # Rubygems' RDoc support is incomplete... Can't seem to find a way
  # to set the start page, or a set of files that should be includable
  # but not processed by rdoc directly
  s.files += FILES_RDOC_EXTRA
  s.files += Dir.glob("{lib,examples,test}/**/*").delete_if do |item|
    item.include?("CVS") || item =~ /~$/
  end
  s.files += %w{LICENSE Rakefile install.rb}
  s.extra_rdoc_files = FILES_RDOC_EXTRA
  s.rdoc_options += %w{--include examples}

  s.require_path = 'lib'
  s.autorequire = 'xml/mapping'

  # s.add_dependency 'rexml'

  s.has_rdoc=true

  s.test_file = 'test/all_tests.rb'

  s.author = 'Olaf Klischat'
  s.email = 'klischat@cs.tu-berlin.de'
  s.homepage = "http://xml-mapping.rubyforge.org"
end



Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true

  # (indirectly) add :rdoc, :test as prerequisites to :package task
  # created by GemPackageTask
  file "#{p.package_dir}/#{p.tgz_file}"  => [ "test_run", :rdoc ]
  file "#{p.package_dir}/#{p.zip_file}" => [ "test_run", :rdoc ]
  file "#{p.package_dir}/#{p.gem_file}" => [ "test_run", :rdoc ]
end



# run "rake package" to generate tgz, zip, gem in pkg/



task :rfpub_rdoc => [:rdoc] do
  p=Rake::SshDirPublisher.new('xml-mapping.rubyforge.org',
                              '/var/www/gforge-projects/xml-mapping/',
                              'doc/api')
  p.upload
end
