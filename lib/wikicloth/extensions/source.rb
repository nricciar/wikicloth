begin
  require 'pygments.rb'
rescue LoadError
end

module WikiCloth
  class SourceExtension < Extension

    VALID_LANGUAGES = [ 'as','applescript','arm','asp','asm','awk','bat','bibtex','bbcode','bison','lua',
      'bms','boo','c','c++','cc','cpp','cxx','h','hh','hpp','hxx','clojure','cbl','cob','cobol','cfc','cfm',
      'coldfusion','csharp','cs','css','d','diff','patch','erlang','erl','hrl','go','hs','haskell','html',
      'htm','xml','xhtml','httpd','js','javascript','matlab','m','perl','cgi','pl','plex','plx','pm','php',
      'php3','php4','php5','php6','python','py','ruby','rb' ]

    # <source lang="language">source code</source>
    #
    element 'source', :skip_html => true, :run_globals => false do |buffer|

      highlight_path = @options[:highlight_path] || '/usr/bin/highlight'
      highlight_options = @options[:highlight_options] || '--inline-css'

      name = buffer.element_name
      content = buffer.element_content
      content = $1 if content =~ /^\s*\n(.*)$/m
      error = nil

      raise I18n.t("lang attribute is required") unless buffer.element_attributes.has_key?('lang')
      raise I18n.t("unknown lang", :lang => buffer.element_attributes['lang'].downcase) unless SourceExtension::VALID_LANGUAGES.include?(buffer.element_attributes['lang'].downcase)

      if defined?(Pygments)
	begin
	  content = "<style type=\"text/css\">\n#{Pygments.css}\n</style>\n"+Pygments.highlight(content, :lexer => buffer.element_attributes['lang'].downcase).gsub!('<pre>', '').gsub!('</pre>', '')
	rescue => err
	  error = "<span class=\"error\">#{err.message}</span>"
	end
      elsif File.exists?(highlight_path)
        begin
          IO.popen("#{highlight_path} #{highlight_options} -f --syntax #{buffer.element_attributes['lang'].downcase}", "r+") do |io|
            io.puts content
            io.close_write
            content = io.read
          end
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end
      else
        content = content.gsub('<','&lt;').gsub('>','&gt;')
      end

      if error.nil?
        "<pre>#{content}</pre>"
      else
        error
      end
    end

  end
end
