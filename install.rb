require 'rbconfig'
require 'find'
require 'ftools'

include Config

# this was adapted from active_record's install.rb

$sitedir = CONFIG["sitelibdir"]
unless $sitedir
  version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
  $libdir = File.join(CONFIG["libdir"], "ruby", version)
  $sitedir = $:.find {|x| x =~ /site_ruby/ }
  if !$sitedir
    $sitedir = File.join($libdir, "site_ruby")
  elsif $sitedir !~ Regexp.quote(version)
    $sitedir = File.join($sitedir, version)
  end
end


# deprecated files that should be removed
# deprecated = %w{ }

# files to install in library path
files = %w-
xml/mapping.rb
xml/xxpath.rb
xml/mapping/base.rb
xml/mapping/standard_nodes.rb
xml/mapping/version.rb
-

# the acual gruntwork
Dir.chdir("lib")
# File::safe_unlink *deprecated.collect{|f| File.join($sitedir, f.split(/\//))}
files.each {|f| 
  File::makedirs(File.join($sitedir, *f.split(/\//)[0..-2]))
  File::install(f, File.join($sitedir, *f.split(/\//)), 0644, true)
}
