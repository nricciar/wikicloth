module WikiCloth
  class MediaExtension < Extension

    require 'mechanize'
    require 'json'

    # parser for media urls
    #
    # Youtube: <media url="http://www.youtube.com/watch?v=[_ID_]">
    #
    element 'media', :skip_html => true, :run_globals => false do |buffer|

      # with regexp retrieve id from youtube url
      id = buffer.get_attribute_by_name("url").scan(/.+?\=(.+)/).first.first

      # if retrieved id
      if !id.nil?

        title = 'Title wasn\'t defined'
        begin
          # get title of video
          a = Mechanize.new
          response = a.get "https://gdata.youtube.com/feeds/api/videos/#{id}?v=2&alt=json"
          body = response.body
          json_data = JSON.parse body
          title = json_data['entry']['title']['$t']
        rescue
        end

        # render html for representing this url as iframe on webpage
        '<div class="video-title">'+ title +
            '</div><iframe width="420" height="315" src="https://www.youtube-nocookie.com/embed/' +
            id.to_s + '" frameborder="0" allowfullscreen></iframe>'

      else

        # else show error message
        WikiCloth.error_template 'Cannot provide embedded video =/'

      end

    end
  end
end
