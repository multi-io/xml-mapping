require 'rdoc/rdoc'
require 'rdoc/generators/html_generator'

module Generators
  class MyHtml < HyperlinkHtml

    def handle_special_ANCHOR(special)
      text = special.text
      unless text =~ /\{(.*?)\}\[a:(.*?)\]/ or text =~ /(\S+)\[a:(.*?)\]/ 
        return text
      end
      label = $1
      name   = $2
      %{<a name="#{name}">#{label}</a>}
    end

    def handle_special_ANCHORREF(special)
      text = special.text
      unless text =~ /\{(.*?)\}\[aref:(.*?)\]/ or text =~ /(\S+)\[aref:(.*?)\]/ 
        return text
      end
      label = $1
      name   = $2
      %{<a href="##{name}">#{label}</a>}
    end

  end

  module MarkUp

    alias_method :markup_old, :markup

    def markup(str, remove_para=false)
      unless defined? @markup
        ### copied from html_generator.rb  -- start
        @markup = SM::SimpleMarkup.new
        ### copied from html_generator.rb  -- end

        @markup.add_special(/(((\{.*?\})|\b\S+?)\[a:(.*?)\])/, :ANCHOR)
        @markup.add_special(/(((\{.*?\})|\b\S+?)\[aref:(.*?)\])/, :ANCHORREF)

        ### copied from html_generator.rb  -- start

        # class names, variable names, file names, or instance variables
        @markup.add_special(/(
                             \b([A-Z]\w*(::\w+)*[.\#]\w+)  #    A::B.meth
                           | \b([A-Z]\w+(::\w+)*)       #    A::B..
                           | \#\w+[!?=]?                #    #meth_name 
                           | \b\w+([_\/\.]+\w+)+[!?=]?  #    meth_name
                           )/x, 
                            :CROSSREF)

        # external hyperlinks
        @markup.add_special(/((link:|https?:|mailto:|ftp:|www\.)\S+\w)/, :HYPERLINK)

        # and links of the form  <text>[<url>]
        @markup.add_special(/(((\{.*?\})|\b\S+?)\[\S+?\.\S+?\])/, :TIDYLINK)
        #      @markup.add_special(/\b(\S+?\[\S+?\.\S+?\])/, :TIDYLINK)

        ### copied from html_generator.rb  -- end
      end
      unless defined? @html_formatter
        @html_formatter = MyHtml.new(self.path, self)
      end

      markup_old(str,remove_para)
    end

  end


end
