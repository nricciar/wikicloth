module WikiCloth
  class MediaExtension < Extension

    # parser for media urls
    #
    # Youtube: <media url="http://www.youtube.com/watch?v=[_ID_]">
    #
    element 'media', :skip_html => true do |buffer|

      # with regexp retrieve id from youtube url
      id = buffer.get_attribute_by_name("url").scan(/.+?\=(.+)/).first.first

      if !id.nil?
        # render html for representing this url as iframe on webpage
        '<iframe width="420" height="315" src="https://www.youtube-nocookie.com/embed/' + id.to_s + '" frameborder="0" allowfullscreen></iframe>'
      else
        WikiCloth.error_template 'Cannot provide video =/'
      end

    end
  end
end
