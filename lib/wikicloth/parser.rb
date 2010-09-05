module WikiCloth

  class Parser < WikiLinkHandler

    def initialize(opt={})
      opt.each { |k,v|
        if v.instance_of?(Proc)
          self.class.send :define_method, k.to_sym do |*args|
            v.call(args)
          end
        end
      }
      @params = opt[:params] || {}
      @wikicloth = WikiCloth.new(:data => opt[:data], :link_handler => self, :params => @params)
    end

    class << self
      def url_for(&block)
        self.send :define_method, 'url_for' do |url|
          block.call(url)
        end
      end

      def external_link(&block)
	self.send :define_method, 'external_link' do |url,text|
	  block.call(url,text)
	end
      end

      def include_resource(&block)
	self.send :define_method, 'include_resource' do |resource,options|
	  options ||= []
	  block.call(resource,options)
	end
      end

      def link_for_resource(&block)
	self.send :define_method, 'link_for_resource' do |prefix,resource,options|
	  options ||= []
	  block.call(prefix,resource,options)
	end
      end

      def section_link(&block)
        self.send :define_method, 'section_link' do |section|
          block.call(section)
        end
      end

      def template(&block)
        self.send :define_method, 'template' do |template|
          block.call(template)
        end
      end

      def link_for(&block)
	self.send :define_method, 'link_for' do |page,text|
	  block.call(page,text)
	end
      end

      def link_attributes_for(&block)
	self.send :define_method, 'link_attributes_for' do |page|
	  block.call(page)
	end
      end
    end

    def to_html
      @wikicloth.to_html
    end

  end

end
