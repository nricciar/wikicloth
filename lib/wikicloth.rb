require 'jcode'
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "core_ext")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_buffer")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_link_handler")
String.send(:include, ExtendedString)

module WikiCloth

  class WikiCloth

    def initialize(opt={})
      self.load(opt[:data],opt[:params]) unless opt[:data].nil? || opt[:data].blank?
      self.options[:link_handler] = opt[:link_handler] unless opt[:link_handler].nil?
    end

    def load(data,p={})
      data.gsub!(/<!--(.|\s)*?-->/,"")
      data = data.gsub(/\{\{(.*?)\}\}/){ |match| expand_templates($1,["."]) }
      self.params = p
      self.html = data
    end

    def expand_templates(template, stack)
      tmpname = template.gsub(/\s/,"_")
      article = self.link_handler.include_template(tmpname.downcase)
 
      if article.nil?
        data = "{{ template }}"
      else
        unless stack.include?(tmpname) 
          data = article.current_revision.body
        else
          data = "template loop! OHNOES!"
        end
        data = data.gsub(/\{\{(.*?)\}\}/){ |match| expand_templates($1,stack + [tmpname])}
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
