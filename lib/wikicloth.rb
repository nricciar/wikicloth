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
      self.sections = get_sections(data)
      self.params = p
      data = self.sections.collect { |s| s[:heading]+s[:content] }.join("")
      data.gsub!(/<!--(.|\s)*?-->/,"")
      data.gsub!(/^[^\s]*\{\{(.*?)\}\}/){ |match| expand_templates($1,["."]) }
      self.html = data
    end

    def sections=(val)
      @sections = val
    end

    def sections
      @sections
    end

    def get_sections(data)
      last_head = "1"
      noedit = false
      sections = [{ :title => "", :content => "", :id => "1", :heading => "" }]

      for line in data.split("\n")
        if line =~ /^([=]{1,6})\s*(.*?)\s*(\1)/
          sections << { :title => $2, :content => "", :heading => "", :id => "" }

          section_depth = $1.length
          section_title = $2

          if last_head.nil?
            last_head = "#{section_depth}"
          else
            tmp = last_head.split(".")
            if tmp.last.to_i < section_depth
              last_head = "#{tmp[0..-1].join(".")}.#{section_depth}"
            elsif tmp.last.to_i == section_depth
              last_head = "#{tmp[0..-1].join(".")}"
            else
              last_head = "#{tmp[0..-2].join(".")}"
            end
          end
          sections.last[:id] = last_head
          sections.last[:heading] = "<h#{section_depth}>" + (noedit == true ? "" :
            "<span class=\"editsection\">[<a href=\"" + self.link_handler.section_link(sections.length-1) +
            "\" title=\"Edit section: #{section_title}\">edit</a>]</span>") +
            " <span class=\"mw-headline\">#{section_title}</span></h#{section_depth}>"
        elsif line =~ /__NOEDITSECTION__/
          noedit = true
        else
          sections.last[:content] += "#{line}\n"
        end
      end
      sections
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
          data = "template loop! OHNOES!"
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
