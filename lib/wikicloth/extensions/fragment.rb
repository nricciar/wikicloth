require 'pygments.rb'
require 'net/http'
require 'json'

module WikiCloth
  class FragmentExtension < Extension

    # <fragment url="http://worker.101companies.org/services/fragment/contributions/haskellNovice/Cut.hs/function/cut"></fragment>
    #
    element 'fragment', :skip_html => true, :run_globals => false do |buffer|

      highlight_options = @options[:highlight_options] || '--inline-css'

      name = buffer.element_name
      #content = buffer.element_content
      #content = $1 if content =~ /^\s*\n(.*)$/m
      content = "TEST"
      error = nil

      #if File.exists?(highlight_path)
        begin
          raise I18n.t("url attribute is required") unless buffer.element_attributes.has_key?('url')
          url = URI(buffer.element_attributes['url'])
          response = Net::HTTP.get_response(url)
          json = JSON.parse(response.body)
          source = json['text']
          lang = json['geshi']
          content = Pygments.highlight(source, :lexer => lang)
        rescue => err
          error = "<span class=\"error\">#{err.message}</span>"
        end
      #else
      #  content = content.gsub('<','&lt;').gsub('>','&gt;')
      #end

      if error.nil?
        "#{content}"
      else
        error
      end
    end

  end
end