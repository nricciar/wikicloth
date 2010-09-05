require 'jcode'
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "core_ext")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_buffer")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_link_handler")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "parser")
String.send(:include, ExtendedString)

module WikiCloth

  class WikiCloth

    def initialize(opt={})
      self.options[:link_handler] = opt[:link_handler] unless opt[:link_handler].nil?
      self.load(opt[:data],opt[:params]) unless opt[:data].nil? || opt[:data].blank?
    end

    def load(data,p={})
      data.gsub!(/<!--(.|\s)*?-->/,"")
      data = data.gsub(/^[^\s]*\{\{(.*?)\}\}/){ |match| expand_templates($1,["."]) }
      self.params = p
      self.html = data
    end

    def expand_templates(template, stack)
      template.strip!
      article = link_handler.template(template)

      if article.nil?
        data = "{{template}}"
      else
        unless stack.include?(template) 
          data = article
        else
          data = "WARNING: TEMPLATE LOOP"
        end
        data = data.gsub(/^[^\s]*\{\{(.*?)\}\}/){ |match| expand_templates($1,stack + [template])}
      end

      data
    end

    def render(opt={})
      self.options = { :output => :html, :link_handler => self.link_handler, :params => self.params }.merge(opt)
      self.options[:link_handler].params = options[:params]
      buffer = WikiBuffer.new("",options)
      self.html.each_char { |c| buffer.add_char(c) }
      buffer.to_s
    end

    def to_html(opt={})
      self.render(opt)
    end

    def link_handler
      self.options[:link_handler] ||= WikiLinkHandler.new
    end

    def html
      @page_data + (@page_data[-1,1] == "\n" ? "" : "\n")
    end

    def params
      @page_params ||= {}
    end

    protected
    def options=(val)
      @options = val
    end

    def options
      @options ||= {}
    end

    def html=(val)
      @page_data = val
    end

    def params=(val)
      @page_params = val
    end

  end

end
