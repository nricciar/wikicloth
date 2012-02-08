module WikiCloth
  class SourceElement < HTMLElementAddon

    VALID_LANGUAGES = [ 'as','applescript','arm','asp','asm','awk','bat','bibtex','bbcode','bison','lua',
      'bms','boo','c','c++','cc','cpp','cxx','h','hh','hpp','hxx','clojure','cbl','cob','cobol','cfc','cfm',
      'coldfusion','csharp','cs','css','d','diff','patch','erlang','erl','hrl','go','hs','haskell','html',
      'htm','xml','xhtml','httpd','js','javascript','matlab','m','perl','cgi','pl','plex','plx','pm','php',
      'php3','php4','php5','php6','python','py','ruby','rb' ]

    def name
      "pre"
    end

    def self.skip_html?
      true
    end

    def self.run_globals?
      false
    end

    def to_s
      highlight_path = @options[:highlight_path] || '/usr/bin/highlight'
      highlight_options = @options[:highlight_options] || '--inline-css'
      self.content = $1 if self.content =~ /^\s*\n(.*)$/m

      if File.exists?(highlight_path)
        begin
          raise "lang attribute is required" unless attributes.has_key?('lang')
          raise "unknown lang '#{attributes['lang'].downcase}'" unless VALID_LANGUAGES.include?(attributes['lang'].downcase)
          IO.popen("#{highlight_path} #{highlight_options} -f --syntax #{attributes['lang'].downcase}", "r+") do |io|
            io.puts self.content
            io.close_write
            self.content = io.read
          end
          del_attribute("lang")
        rescue => err
          self.content = "<span class=\"error\">#{err.message}</span>"
        end
      else
        self.content = val.gsub('<','&lt;').gsub('>','&gt;')
      end

      super
    end

  end

  Parser.register_html_element("source", SourceElement)
end
