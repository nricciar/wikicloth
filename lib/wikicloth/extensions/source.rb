require 'pygments.rb'

module WikiCloth
  class SourceExtension < Extension

    VALID_LANGUAGES = [ 'as','applescript','arm','asp','asm','awk','bat','bibtex','bbcode','bison','lua',
      'bms','boo','c','c++','cc','cpp','cxx','h','hh','hpp','hxx','clojure','cbl','cob','cobol','cfc','cfm',
      'coldfusion','csharp','cs','css','d','diff','patch','erlang','erl','hrl','go','hs','haskell','html',
      'htm','xml','xhtml','httpd','js','javascript','matlab','m','perl','cgi','pl','plex','plx','pm','php',
      'php3','php4','php5','php6','python','py','ruby','rb', 'java', 'sql' ]

    # <source lang="language">source code</source>
    #
    element 'syntaxhighlight', :skip_html => true, :run_globals => false do |buffer|
      name = buffer.element_name
      content = buffer.element_content
      content = $1 if content =~ /^\s*\n(.*)$/m
      error = nil
        begin
          raise I18n.t("lang/language attribute is required") unless (buffer.element_attributes.has_key?('lang') or buffer.element_attributes.has_key?('language'))
          #raise I18n.t("unknown lang", :lang => buffer.element_attributes['lang'].downcase) unless LuaExtension::VALID_LANGUAGES.include?(buffer.element_attributes['lang'].downcase)
          if buffer.element_attributes.has_key?('lang')
            lexer = buffer.element_attributes['lang'].downcase 
          elsif buffer.element_attributes.has_key?('language')
            lexer = buffer.element_attributes['language'].downcase 
          end     
          #content = "<style type=\"text/css\">\n#{Pygments.css}\n</style>\n"+Pygments.highlight(content, :lexer => buffer.element_attributes['lang'].downcase).gsub!('<pre>', '').gsub!('</pre>', '')
          content = Pygments.highlight(content, :lexer => lexer)#.gsub!('<pre>', '').gsub!('</pre>', '')
          puts "Content: #{content}"
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end
      if error.nil?
        "#{content}"
      else
        error
      end
    end
  end
end
