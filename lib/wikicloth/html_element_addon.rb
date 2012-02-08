require 'builder'

module WikiCloth
  class HTMLElementAddon

    def initialize(options={})
      @options = options
      name = 'element'
    end

    def self.skip_html?
      false
    end

    def self.run_globals?
      true
    end

    def options
      @options
    end

    def options=(val)
      @options = val
    end

    def name
      @name
    end

    def name=(val)
      @name = val
    end

    def content
      @content ||= ''
      @content
    end

    def content=(val)
      @content = val
    end

    def attributes
      @attributes ||= {}
      @attributes
    end

    def attributes=(val)
      @attributes = val
    end

    def add_attribute(name,value)
      attributes[name] = value
    end

    def del_attribute(name)
      attributes.delete(name)
    end

    def delete_attribute(name)
      del_attribute(name)
    end

    def to_s
      xml = Builder::XmlMarkup.new
      xml.tag!(name, attributes) { |x| x << content }
    end

  end
end
