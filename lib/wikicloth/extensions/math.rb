module WikiCloth
  class MathElement < HTMLElementAddon

    def self.skip_html?
      true
    end

    def to_s
      blahtex_path = @options[:blahtex_path] || '/usr/bin/blahtex'
      blahtex_png_path = @options[:blahtex_png_path] || '/tmp'
      blahtex_options = @options[:blahtex_options] || '--texvc-compatible-commands --mathml-version-1-fonts --disallow-plane-1 --spacing strict'

      if File.exists?(blahtex_path)
        begin
          response = `echo '#{self.content}' | #{blahtex_path} #{blahtex_options} --png --mathml --png-directory #{blahtex_png_path}`
          xml_response = REXML::Document.new(response).root

          if @options[:blahtex_html_prefix]
            file_md5 = xml_response.elements["png/md5"].text
            self.name = "img"
            self.attributes = { "src" => File.join(@options[:blahtex_html_prefix],"#{file_md5}.png") }
            self.content = nil
          else
            html = xml_response.elements["mathml/markup"].text
            self.name = "math"
            self.add_attribute("xmlns", "http://www.w3.org/1998/Math/MathML")
            self.content = xml_response.elements["mathml/markup"].children.to_s
          end
        rescue => err
          error(I18n.t("unable to parse mathml", :error => err))
        end
      else
        error(I18n.t("blahtex binary not found", :path => blahtex_path))
      end

      super
    end

    def error(message)
      self.name = "span"
      self.attributes = { "class" => "error" }
      self.content = message
    end

  end

  Parser.register_html_element("math", MathElement)
end
