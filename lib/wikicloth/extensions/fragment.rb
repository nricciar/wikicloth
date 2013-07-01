require 'pygments.rb'
require 'net/http'
require 'json'

module WikiCloth

  class FragmentError < StandardError
    def initialize(message = 'Internal error: 500')
      if message.strip == ''
        message = 'Internal error: 500'
      end
      super
    end
  end

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
      response = Net::HTTP.get_response(URI(resourceUrl))
      if response.code == '500'
        raise FragmentError, 'Retrieved empty json from discovery service'
      end
      JSON.parse(response.body)
    end

    # <fragment>
    # ....
    # </fragment>
    element 'fragment', :skip_html => true, :run_globals => false do |buffer|
      error = nil

      begin
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
        json = get_json(url)
        content = Pygments.highlight(json['content'], :lexer => json['geshi'])
      rescue FragmentError => err
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
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
        json = get_json(url)
        name = json['name']
        content = Pygments.highlight(json['content'], :lexer => json['geshi'])
      rescue FragmentError => err
        error = WikiCloth.error_template err.message
      end

      need_to_show = buffer.element_attributes.has_key?('show') && (buffer.element_attributes['show'] == "true")

      if error.nil?
        if need_to_show
          "#{content}"
        else
          "<a href=\"http://101companies.org/resources#{url}?format=html\">#{name}</a>"
        end
      else
        if need_to_show
          error
        else
          require 'pathname'
          file_name = Pathname.new(buffer.element_attributes['url']).basename
          "<a class='fragment-failed' href='#'>#{file_name}</a>"
        end
      end

    end

    # <folder>
    # ....
    # </folder>
    element 'folder', :skip_html => true, :run_globals => false do |buffer|
      # TODO: is it used at all?
      begin
        raise FragmentError, I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
        url = buildUrl(buffer.element_attributes['url'])
      rescue FragmentError => err
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
