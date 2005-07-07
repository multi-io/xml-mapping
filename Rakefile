# -*- ruby -*-
# adapted from active_record's Rakefile

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'
require 'rake/contrib/sshpublisher'

require File.dirname(__FILE__)+"/lib/xml/mapping/version"


# yeah -- it's just stupid that these are private

class Rake::RDocTask
  public :rdoc_target
end

class Rake::PackageTask
  public :tgz_file, :zip_file
end

class Rake::GemPackageTask
  public :gem_file
end


FILES_RDOC_EXTRA=%w{README README_XPATH doc/xpath_impl_notes.txt}


desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new(:test) { |t|
  t.test_files = ["test/all_tests.rb"]
  t.verbose = true
}

# runs tests only if sources have changed since last succesful run of
# tests
file "test_run" => FileList.new('lib/**/*.rb','test/**/*.rb') do
  Task[:test].invoke
  touch "test_run"
end



Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = "XML::Mapping -- Simple, extensible Ruby-to-XML (and back) mapper"
  rdoc.options << '--line-numbers --inline-source --accessor cattr_accessor=object --include examples'
  rdoc.rdoc_files.include(*FILES_RDOC_EXTRA)
  rdoc.rdoc_files.include('lib/**/*.rb')

  # additional file dependencies for the rdoc task
  #   this somewhat of a black art because RDocTask doesn't document the
  #   prerequisite of its rdoc task (<rdoc_dir>/index.html)
  file rdoc.rdoc_target => ['examples/company.xml',
                            'examples/company.rb',
                            #'examples/company_usage.intout',
                            'examples/order_usage.intout',
                            'examples/time_augm.intout',
                            'examples/xpath_usage.intout',
                            'examples/xpath_ensure_created.intout',
                            'examples/xpath_create_new.intout',
                            'examples/xpath_pathological.intout',
                            'examples/xpath_docvsroot.intout',
                            'examples/order_signature_enhanced_usage.intout'
                           ]
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
for f in %w{examples/company_usage
            examples/order_usage
            examples/order_signature_enhanced_usage
            examples/time_augm
            examples/xpath_usage
            examples/xpath_ensure_created
            examples/xpath_create_new
            examples/xpath_pathological
            examples/xpath_docvsroot} do
  file "#{f}.intout" => ["#{f}.intin.rb", 'examples/company.xml']
  file "#{f}.intout" => FileList.new("lib/**/*.rb")
  file "#{f}.intout" => FileList.new("examples/**/*.rb")
end


spec = Gem::Specification.new do |s|
  s.name = 'xml-mapping'
  s.version = XML::Mapping::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary =
    "An easy to use, extensible library for mapping Ruby objects to XML and back. Includes an XPath interpreter."
  s.files = Dir.glob("{lib,examples,test}/**/*").delete_if do |item|
    item.include?("CVS") || item =~ /~$/
  end
  s.files += %w{LICENSE Rakefile}
  s.files += FILES_RDOC_EXTRA
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
