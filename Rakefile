# -*- ruby -*-
# adapted from active_record's Rakefile

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'
#require 'rake/contrib/sshpublisher'

require File.dirname(__FILE__)+"/lib/xml/mapping/version"


desc "Default Task"
task :default => [ :test ]

Rake::TestTask.new(:test) { |t|
  t.test_files = ["test/all_tests.rb"]
  t.verbose = true
}


Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = "XML::Mapping -- Simple, extensible Ruby-to-XML (and back) mapper"
  rdoc.options << '--line-numbers --inline-source --accessor cattr_accessor=object --include examples'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')

  # additional file dependencies for the rdoc task
  #   this somewhat of a black art because RDocTask doesn't document the
  #   prerequisite of its rdoc task (<rdoc_dir>/index.html)
  #file rdoc.rdoc_target => ['examples/company.xml','examples/company.rb'] # private method
  file "#{rdoc.rdoc_dir}/index.html" => ['examples/company.xml','examples/company.rb','examples/company_usage.intout']
}

rule '.intout' => '.intin.rb' do |task|
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
    File.delete task.name
    raise
  ensure
    $stdout = old_stdout
    Dir.chdir old_wd
  end
end


spec = Gem::Specification.new do |s|
  s.name = 'xml-mapping'
  s.version = XML::Mapping::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary =
    "XML::Mapping is a simple, extensible, bidirectional Ruby-to-XML mapper."
  s.files = Dir.glob("{doc,lib,examples,test}/**/*").delete_if do |item|
    item.include?("CVS") || item.include?("rdoc") || item =~ /~$/
  end
  s.files << "README"
  s.files << "LICENSE"
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
end
