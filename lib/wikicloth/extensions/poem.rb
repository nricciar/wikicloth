module WikiCloth
  class PoemExtension < Extension

    # <poem>poem content (to preserve spacing)</poem>
    #
    element 'poem' do |buffer|
      buffer.element_content.gsub!(/\A\n/,"") # remove new line at beginning of string
      buffer.element_content.gsub!(/\n\z/,"") # remove new line at end of string
      buffer.element_content.gsub!(/^\s+/) { |m| "&nbsp;" * m.length } # replace all spaces at beginning of line with &nbsp;
      buffer.element_content.gsub!(/\n/,'<br />') # replace all new lines with <br />
      "<div class=\"poem\">#{buffer.element_content}</div>"
    end

  end
end
