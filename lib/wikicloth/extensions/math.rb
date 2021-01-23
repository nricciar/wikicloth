module WikiCloth
  class MathExtension < Extension

    # <math>latex markup</math>
    #
    element 'math', :skip_html => true, :run_globals => false do |buffer|

      blahtex_path = @options[:blahtex_path] || '/usr/bin/blahtex'
      blahtex_png_path = @options[:blahtex_png_path] || '/tmp'
      blahtex_options = @options[:blahtex_options] || '--texvc-compatible-commands --mathml-version-1-fonts --disallow-plane-1 --spacing strict'

      if File.exists?(blahtex_path) && @options[:math_formatter] != :google
        begin
          # pass tex markup to blahtex
          response = IO.popen("#{blahtex_path} #{blahtex_options} --png --mathml --png-directory #{blahtex_png_path}","w+") do |pipe|
            pipe.write(buffer.element_content)
            pipe.close_write
            pipe.gets
          end

          xml_response = REXML::Document.new(response).root

          if @options[:blahtex_html_prefix]
            # render as embedded image
            file_md5 = xml_response.elements["png/md5"].text
            "<img src=\"#{File.join(@options[:blahtex_html_prefix],"#{file_md5}.png")}\" />"
          else
            # render as mathml
            "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">#{xml_response.elements["mathml/markup"].children.to_s}</math>"
          end
        rescue => err
          # blahtex error
          "<span class=\"error\">#{I18n.t("unable to parse mathml", :error => err)}</span>"
        end
      else
        # if blahtex does not exist fallback to google charts api
        encoded_string = URI.encode_www_form_component(buffer.element_content)
        "<img src=\"https://chart.googleapis.com/chart?cht=tx&chl=#{encoded_string}\" />"
      end
    end

  end
end
