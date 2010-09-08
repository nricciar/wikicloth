module WikiCloth

  class Parser < WikiLinkHandler

    def initialize(opt={})
      opt.each { |k,v|
        if v.instance_of?(Proc)
          self.class.send :define_method, k.to_sym do |*args|
            self.instance_exec(args,&v)
          end
        end
      }
      @params = opt[:params] || {}
      @wikicloth = WikiCloth.new(:data => opt[:data], :link_handler => self, :params => @params)
    end

    # The Wiki document seperated into sections
    def sections
      @wikicloth.sections
    end

    # Replace a section, along with any sub-section in the document
    def put_section(num,data)
      depth = nil
      start = false
      ret = ""

      # build sections before changed section
      self.sections[0..num-1].each do |s|
        if s[:id] =~ /.([0-9]+)-([0-9]+)$/
          head = "=" * $1.to_i
          ret += "\n#{head} #{s[:title]} #{head}\n"
        end
        ret += s[:content]
      end

      # add in the changed section
      ret += "#{data}\n"

      # build sections after the changed section
      self.sections[num..-1].each do |section|
        test = section[:id].split("-").first.split(".")
        start = true unless depth.nil? || test.length > depth
        depth = section[:id].split("-").first.split(".").length if depth.nil?

        if start == true
          if section[:id] =~ /.([0-9]+)-([0-9]+)$/
            head = "=" * $1.to_i
            ret += "\n#{head} #{section[:title]} #{head}\n"
          end
          ret += section[:content]
        end
      end

      # reload wiki data
      @wikicloth = WikiCloth.new(:data => ret, :link_handler => self, :params => @params)
    end

    # Get the section, along with any sub-section of the document
    def get_section(num)
      ret = ""
      depth = nil

      for section in self.sections[num..-1]
        test = section[:id].split("-").first.split(".")
        break unless depth.nil? || test.length > depth
        depth = section[:id].split("-").first.split(".").length if depth.nil?

        if section[:id] =~ /.([0-9]+)-([0-9]+)$/
          head = "=" * $1.to_i
          ret += "#{head} #{section[:title]} #{head}\n"
        end

	ret += "#{section[:content]}\n"
      end

      ret
    end

    class << self
      def url_for(&block)
        self.send :define_method, 'url_for' do |url|
          self.instance_exec(url, &block)
        end
      end

      def toc(&block)
        self.send :define_method, 'toc' do |sections|
          self.instance_exec(sections, &block)
        end
      end

      def function(&block)
	self.send :define_method, 'function' do |name, params|
	  self.instance_exec(name, params, &block)
	end
      end

      def external_link(&block)
	self.send :define_method, 'external_link' do |url,text|
	  self.instance_exec(url,text,&block)
	end
      end

      def mime(bla,&block)
	puts "defined #{bla}"
      end

      def include_resource(&block)
	self.send :define_method, 'include_resource' do |resource,options|
	  options ||= []
	  self.instance_exec(resource,options,&block)
	end
      end

      def link_for_resource(&block)
	self.send :define_method, 'link_for_resource' do |prefix,resource,options|
	  options ||= []
	  self.instance_exec(prefix,resource,options,&block)
	end
      end

      def section_link(&block)
        self.send :define_method, 'section_link' do |section|
          self.instance_exec(section,&block)
        end
      end

      def template(&block)
        self.send :define_method, 'template' do |template|
          self.instance_exec(template,&block)
        end
      end

      def link_for(&block)
	self.send :define_method, 'link_for' do |page,text|
	  self.instance_exec(page,text,&block)
	end
      end

      def link_attributes_for(&block)
	self.send :define_method, 'link_attributes_for' do |page|
	  self.instance_exec(page,&block)
	end
      end
    end

    def to_html
      @wikicloth.to_html
    end

    def to_wiki
      ret = ""
      for section in self.sections
        if section[:id] =~ /.([0-9]+)-([0-9]+)$/
          head = "=" * $1.to_i
          ret += "#{head} #{section[:title]} #{head}\n#{section[:content]}"
        else
          ret += section[:content]
        end
      end
      ret
    end

  end

end
