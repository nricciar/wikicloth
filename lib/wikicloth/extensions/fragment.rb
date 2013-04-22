require 'pygments.rb'
require 'net/http'
require 'json'
#require 'debug'

module WikiCloth
  class FragmentExtension < Extension

    def initialize(options={})
      puts "WikiCloth --> initialize"
      #puts WikiCloth::Parser::context
    end

    def buildUrl(url)
      puts "Buidling url for #{url}"
      if url.starts_with?("/")
        #absolute path -- keep it as is
        return url
      else
        #relative path  
        ns = Parser.context[:ns]
        title = Parser.context[:title]
        puts "Context:"
        puts Parser.context
        puts "NS: #{ns} TITLE: #{title}"
        case ns
          when "contribution"
            return "/contributions/#{title}/#{url}"
          when "concept"
            return "/concepts/#{title}/#{url}" 
        end    
      end  
    end
      
    def get_json(url)
      resourceUrl = "http://101companies.org/resources#{url}"
      puts "URL: #{resourceUrl}"
      url = URI(resourceUrl)
      response = Net::HTTP.get_response(url)
      json = JSON.parse(response.body)
      json
    end

    # <fragment>
    # ....
    # </fragment>
    element 'fragment', :skip_html => true, :run_globals => false do |buffer|
      error = nil

        begin
          raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
          url = buildUrl(buffer.element_attributes['url'])
          json = get_json(url)  
          source = json['content']
          lang = json['geshi']
          content = Pygments.highlight(source, :lexer => lang)
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end
      if error.nil?
        "<div style=\"float:right; margin-right:60px\"><a href=\"http://101companies.org/resources#{url}?format=html\" target=\"_blank\"\>Discover</a></div>#{content}"
      else
        error
      end
    end
    
    # <file>
    # ....
    # </file>
    element 'file', :skip_html => true, :run_globals => false do |buffer|
      error = nil
        begin
          raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
          json = get_json(buildUrl(buffer.element_attributes['url'])) 
          source = json['content']
          lang = json['geshi']
          github = json['github']
          name = json['name']
          content = Pygments.highlight(source, :lexer => lang)
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end

      if error.nil?
        if buffer.element_attributes.has_key?('show')
          toShow = (buffer.element_attributes['show'] == "true")
          if toShow
            "#{content}"
          else
            "<div><a href=\"#{github}\">#{name}</a></div>"  
          end  
        else
          #render a link to the file by default
          "<div><a href=\"#{github}\">#{name}</a></div>"  
        end  
      else
        error
      end
    end
  
    # <folder>
    # ....
    # </folder>
    element 'folder', :skip_html => true, :run_globals => false do |buffer|
      error = nil
      #puts "FOLDER"
        begin
          raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
          json = get_json(buildUrl(buffer.element_attributes['url'])) 
          link = json['github']
          #folders = json['folders'].map { |f|  "#<a href=\"#{f['resource']}\">#{f['name']}</a>" }
          #puts "folders: #{folders}"
          #files = json['files'].map { |f| "#<a href=\"#{f['resource']}\">#{f['name']}</a>" }
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end

      if error.nil?
        #"Folders: " + folders.join(" ") + " Files: " + files.join(" ")
        "<div><a href=\"#{link}\">#{buffer.element_attributes['url']}</a></div>"
      else
        error
      end
    end 
  end
end