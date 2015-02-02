require 'builder'
# if i18n gem loaded use it instead
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "i18n") unless defined?(I18n)
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks) if defined?(I18n::Backend::Simple)
I18n.load_path += Dir[File.join(File.expand_path(File.dirname(__FILE__)), "../lang/*.yml")].collect { |f| f }

require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "version")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "core_ext")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "namespaces")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "extension")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "section")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_buffer")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "wiki_link_handler")
require File.join(File.expand_path(File.dirname(__FILE__)), "wikicloth", "parser")

String.send(:include, ExtendedString)

module WikiCloth

  class WikiCloth

    def initialize(opt={})
      self.options.merge!(opt)
      self.options[:extensions] ||= []
      self.options[:link_handler] = opt[:link_handler] unless opt[:link_handler].nil?
      self.load(opt[:data],opt[:params]) unless opt[:data].nil?
      @current_line = 1
      @current_row = 0
    end

    def load(data,p={})
      depth = 1
      count = 0
      root = [self.sections]

      # parse wiki document into sections
      data.each_line do |line|
        if line =~ /^([=]{1,6})\s*(.*?)\s*(\1)/
          root << root.last[-1].children if $1.length > depth
          root.pop if $1.length < depth
          depth = $1.length
          root.last << Section.new(line, get_id_for($2.gsub(/\s+/,'_')))
          count += 1
        else
          root.last[-1] << line
        end
      end

      # if we find template variables assume document is
      # a template
      self.sections.first.template = true if data =~ /\{\{\{\s*([A-Za-z0-9]+)\s*\}\}\}/

      # If there are more than four sections enable automatic
      # table of contents
      self.sections.first.auto_toc = true unless count < 4 || data =~ /__(NO|)TOC__/

      self.params = p
    end

    def render(opt={})
      self.options = { :noedit => false, :fast => true, :output => :html, :link_handler => self.link_handler, 
	:params => self.params, :sections => self.sections }.merge(self.options).merge(opt)
      self.options[:link_handler].params = options[:params]

      I18n.locale = self.options[:locale] if self.options[:locale]

      data = self.sections.collect { |s| s.render(self.options) }.join
      data.gsub!(/<!--(.|\s)*?-->/,"")
      data << "\n" if data.last(1) != "\n"
      data << "garbage"

      buffer = WikiBuffer.new("",options)

      begin
        if self.options[:fast]
          until data.empty?
            case data
            when /\A\w+/
              data = $'
              @current_row += $&.length
              buffer.add_word($&)
            when /\A[^\w]+(\w|)/m
              data = $'
              $&.each_char { |c| add_current_char(buffer,c) }
            end
          end
        else
          data.each_char { |c| add_current_char(buffer,c) }
        end
      rescue => err
        debug_tree = buffer.buffers.collect { |b| b.debug }.join("-->")
        puts I18n.t("unknown error on line", :line => @current_line, :row => @current_row, :tree => debug_tree)
        raise err
      end

      buffer.eof()
      buffer.send("to_#{self.options[:output]}")
    end

    def sections
      @sections ||= [Section.new]
    end

    def to_html(opt={})
      self.render(opt.merge(:output => :html))
    end

    def link_handler
      self.options[:link_handler] ||= WikiLinkHandler.new
    end

    def params
      @page_params ||= {}
    end

    def options
      @options ||= {}
    end

    def method_missing(method, *args)
      if self.link_handler.respond_to?(method)
        self.link_handler.send(method, *args)
      else
        super(method, *args)
      end
    end

    protected
    def add_current_char(buffer,c)
      if c == "\n"
        @current_line += 1
        @current_row = 1
      else
        @current_row += 1
      end
      buffer.add_char(c)
    end

    def sections=(val)
      @sections = val
    end

    def get_id_for(val)
      val.gsub!(/[^A-Za-z0-9_]+/,'')
      @idmap ||= {}
      @idmap[val] ||= 0
      @idmap[val] += 1
      @idmap[val] == 1 ? val : "#{val}-#{@idmap[val]}"
    end

    def options=(val)
      @options = val
    end

    def params=(val)
      @page_params = val
    end

  end

end
