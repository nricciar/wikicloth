require 'pygments.rb'
require 'net/http'
require 'json'
#require 'debug'

module WikiCloth
  class FragmentExtension < Extension

    def buildUrl(url)
      if url.start_with?("/")
        #absolute path -- keep it as is
        return url
      else
        #relative path
        ns = Parser.context[:ns]
        title = Parser.context[:title]
        case ns
          when "Contribution"
            return "/contributions/#{title}/#{url}"
          when "Concept"
            return "/concepts/#{title}/#{url}"
        end
      end

    end

    def get_json(url)
      resourceUrl = "http://101companies.org/resources#{url}"
      JSON.parse((Net::HTTP.get_response(URI(resourceUrl))).body)
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
        content = Pygments.highlight(json['content'], :lexer => json['geshi'])
      rescue => err
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        "<div style=\"float:right; margin-right:60px\"><a href=\"http://101companies.org/resources#{url}?"+
            "format=html\" target=\"_blank\"\>Explore</a></div>#{content}"
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
        #raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
        json = get_json(url)
        name = json['name']
        content = Pygments.highlight(json['content'], :lexer => json['geshi'])
      rescue => err
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        if buffer.element_attributes.has_key?('show') && (buffer.element_attributes['show'] == "true")
          "#{content}"
        else
          require 'pathname'
          file_name = Pathname.new(buffer.element_attributes['url']).basename
          "<a href=\"http://101companies.org/resources#{url}?format=html\">#{file_name}</a>"
        end
      else
        error
      end

    end

    # <folder>
    # ....
    # </folder>
    element 'folder', :skip_html => true, :run_globals => false do |buffer|
      # TODO: is it used at all?
      begin
        raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
      rescue
        error = WikiCloth.error_template err.message
      end

      if error.nil?
        "<a href=\"http://101companies.org/resources#{url}?format=html\">#{buffer.element_attributes['url']}</a>"
      else
        error
      end

    end
  end
end
