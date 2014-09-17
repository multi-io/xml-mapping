# RDocTask runs rdoc in a subshell (TODO: no longer (as of May 2010)),
# making it impossible to extend RDoc in Ruby, like rdoc_ext does. And
# it's not whitespace-safe or shell-metacharacter-safe either! So...

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'rdoc/rdoc'

class MyRDocTask < Rake::RDocTask

  def define
    ### copied from rdoctask.rb --start
    if rdoc_task_name != "rdoc"
      desc "Build the RDOC HTML Files"
    else
      desc "Build the #{rdoc_task_name} HTML Files"
    end
    task rdoc_task_name
    
    desc "Force a rebuild of the RDOC files"
    task rerdoc_task_name => [clobber_task_name, rdoc_task_name]
      
    desc "Remove rdoc products" 
    task clobber_task_name do
      rm_r rdoc_dir rescue nil
    end
      
    task :clobber => [clobber_task_name]
      
    directory @rdoc_dir
    task rdoc_task_name => [rdoc_target]
    file rdoc_target => @rdoc_files + [Rake.application.rakefile] do
      rm_r @rdoc_dir rescue nil
      @before_running_rdoc.call if @before_running_rdoc
      args = option_list + @rdoc_files
      if @external
        argstring = args.join(' ')
        sh %{ruby -Ivendor vender/rd #{argstring}}
      else
        require 'rdoc/rdoc'
        ### copied from rdoctask.rb --end
        #RDoc::RDoc.new.document(args)
        r = RDoc::RDoc.new
        r.document(['-o', @rdoc_dir] + option_list + @rdoc_files)
      end
    end
    self
  end

  def define_disabled
    ### copied from rdoctask.rb --start
    if name.to_s != "rdoc"
      desc "Build the RDOC HTML Files"
    end

    desc "Build the #{name} HTML Files"
    task name
    
    desc "Force a rebuild of the RDOC files"
    task paste("re", name) => [paste("clobber_", name), name]
    
    desc "Remove rdoc products" 
    task paste("clobber_", name) do
      rm_r rdoc_dir rescue nil
    end

    task :clobber => [paste("clobber_", name)]
    
    directory @rdoc_dir
    task name => [rdoc_target]

    file rdoc_target => @rdoc_files + [$rakefile] do
      rm_r @rdoc_dir rescue nil
      ### copied from rdoctask.rb --end
      # opts = option_list.join(' ')
      # sh %{rdoc -o #{@rdoc_dir} #{opts} #{@rdoc_files}}

      r = RDoc::RDoc.new
      r.document(['-o', @rdoc_dir] + option_list + @rdoc_files)
    end
    self
  end

  def option_list
    result = @options.dup
    #result << "--main" << "'#{main}'" if main
    result << "--main" << main if main
    #result << "--title" << "'#{title}'" if title
    result << "--title" << title if title
    #result << "-T" << "'#{template}'" if template
    result << "-T" << template if template
    result
  end


  # yeah -- it's just stupid that this one is private
  public :rdoc_target

end
