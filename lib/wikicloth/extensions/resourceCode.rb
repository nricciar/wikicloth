require 'pygments.rb'
require 'net/http'
require 'json'

module WikiCloth
  class ResourceCodeExtension < Extension

    element 'resourcecode', :skip_html => true, :run_globals => false do |buffer|
      error = nil
      begin
        raise I18n.t("resource attribute is required") unless buffer.element_attributes.has_key?('resource')
        raise I18n.t("lang attribute is required") unless buffer.element_attributes.has_key?('lang')
        raise I18n.t("index attribute is required") unless buffer.element_attributes.has_key?('index')
        resource = buffer.element_attributes['resource']
        lexer = buffer.element_attributes['lang'].downcase
        index = buffer.element_attributes['index']
        codeUrl = "http://worker.101companies.org/services/termResourcesCode/Fold/#{resource}/#{index}.json"
        url = URI(codeUrl)
        response = Net::HTTP.get_response(url)
        json = JSON.parse(response.body)
        content = Pygments.highlight(json["code"], :lexer => lexer)
      rescue => err
          error = WikiCloth.error_template err.message
      end
      if error.nil?
        content
      else
        error
      end
    end
  end
end
