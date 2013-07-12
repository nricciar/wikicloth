module WikiCloth
  class MediaExtension < Extension

    require 'mechanize'
    require 'json'

    # parser for media urls
    #
    # Youtube: <media url="http://www.youtube.com/watch?v=[_ID_]">
    # Slideshare: <media url="[_SLIDESHARE_URL_]">
    #
    element 'media', :skip_html => true, :run_globals => false do |buffer|

      # assume, that nothing will be rendered
      to_return = WikiCloth::error_template "No media information will be rendered"

      # retrieve from url param youtube_id of youtube video
      youtube_id = nil
      begin
        # with regexp retrieve youtube_id from youtube url
        youtube_id = buffer.get_attribute_by_name("url").scan(/.+?\=(.+)/).first.first
      rescue
      end

      # if retrieved youtube_id
      if !youtube_id.nil?

        title = 'Title wasn\'t defined'
        begin
          # get title of video
          a = Mechanize.new
          # send request to youtube api
          response = a.get "https://gdata.youtube.com/feeds/api/videos/#{youtube_id}?v=2&alt=json"
          # retrieve body of request
          body = response.body
          # parse request body's JSON
          json_data = JSON.parse body
          # get the title of video
          title = json_data['entry']['title']['$t']
        rescue
        end

        # render html for representing this url as iframe on webpage
        to_return = '<div class="video-title">'+ title +
            '</div><iframe width="420" height="315" src="https://www.youtube-nocookie.com/embed/' +
            youtube_id.to_s + '" frameborder="0" allowfullscreen></iframe>'

      end

      slideshare_url = buffer.get_attribute_by_name("url")

      # primitive check if it's slideshare link
      found_slideshare_url = slideshare_url.match /(slideshare)/i

      # if this is slideshare url
      if !found_slideshare_url.nil?

        begin
          # create timestamp for request
          timestamp = Time.now.to_i.to_s

          # do api request to slideshare and parse retrieved xml
          resp  = Nokogiri.XML(Mechanize.new.get('https://www.slideshare.net/api/2/get_slideshow', {
              "slideshow_url" => slideshare_url,
              "api_key" => ENV["SLIDESHARE_API_KEY"],
              "hash" => Digest::SHA1.hexdigest(ENV["SLIDESHARE_API_SECRET"] + timestamp),
              "ts" => timestamp
          }).body)

          # check, if you retrieved some information
          slideshare_embed = resp.root.xpath("Embed").text

          if slideshare_embed.empty?
            to_return = WikiCloth::error_template "Failed API request =/"
          else
            # render html for slideshare
            to_return = "<div slideshare-url='#{slideshare_url}' class='slideshare-slide'>#{slideshare_embed}</div>"
          end

        rescue
          to_return = WikiCloth::error_template "Failed to retrieve slides"
        end

      end

      to_return

    end
  end
end
