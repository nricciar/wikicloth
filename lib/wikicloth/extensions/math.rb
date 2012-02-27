module WikiCloth
  class MathExtension < Extension

    element 'math', :skip_html => true, :run_globals => false do |buffer|

      blahtex_path = @options[:blahtex_path] || '/usr/bin/blahtex'
      blahtex_png_path = @options[:blahtex_png_path] || '/tmp'
      blahtex_options = @options[:blahtex_options] || '--texvc-compatible-commands --mathml-version-1-fonts --disallow-plane-1 --spacing strict'

      if File.exists?(blahtex_path)
        begin
          response = `echo '#{buffer.element_content}' | #{blahtex_path} #{blahtex_options} --png --mathml --png-directory #{blahtex_png_path}`
          xml_response = REXML::Document.new(response).root

          if @options[:blahtex_html_prefix]
            file_md5 = xml_response.elements["png/md5"].text
            return "<img src=\"#{File.join(@options[:blahtex_html_prefix],"#{file_md5}.png")}\" />"
          else
            html = xml_response.elements["mathml/markup"].text
            return "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">#{xml_response.elements["mathml/markup"].children.to_s}</math>"
          end
        rescue => err
          return "<span class=\"error\">#{I18n.t("unable to parse mathml", :error => err)}</span>"
        end
      else
        return "<span class=\"error\">#{I18n.t("blahtex binary not found", :path => blahtex_path)}</span>"
      end

    end

  end
end
