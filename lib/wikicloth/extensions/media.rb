module WikiCloth
  class MediaExtension < Extension

    require 'HTTParty'
    require 'Nokogiri'
    require 'json'

    def get_slideshare_slide(url)
      # do api request to slideshare and parse retrieved xml
      begin
        timestamp = Time.now.to_i.to_s
        response  = Nokogiri.XML HTTParty.get('https://www.slideshare.net/api/2/get_slideshow',
          :body => {
            "slideshow_url" => url,
            "api_key" => ENV["SLIDESHARE_API_KEY"],
            "hash" => Digest::SHA1.hexdigest(ENV["SLIDESHARE_API_SECRET"] + timestamp),
            "ts" => timestamp
          }
        ).body
      end
      return WikiCloth::error_template "Failed to retrieve slides" if !(defined? response)
      # retrieve embed and download link from response
      embed = response.root.xpath("Embed").text
      download_link = response.root.xpath("DownloadUrl").text
      # prepare special link for rails app
      if !download_link.empty?
        require 'cgi'
        app_download_link ="<a target='_blank' href='/get_slide/#{CGI.escape(url)}' download-link='#{download_link}'>"+
          "<i class='icon-download-alt'></i> Download slides</a>"
      end
      # retrieved embed
      if embed
        "<div class='slideshare-slide'>#{embed}<p>#{(defined? app_download_link) ? app_download_link : ''}</p></div>"
      else
        WikiCloth::error_template "Failed to retrieve slides"
      end
    end

    # return youtube id or nil
    def get_youtube_video_id(url)
      # find id
      result = url.match /https*\:\/\/.*youtube\.com\/watch\?v=(.*)/
      # return id or nil
      result ? result[1] : nil
    end

    # retrieve youtube embed by youtube id
    def get_youtube_video(id)
      begin
        resp_body = (HTTParty.get "https://gdata.youtube.com/feeds/api/videos/#{id}?v=2&alt=json").body
        title = (JSON.parse resp_body)['entry']['title']['$t']
      rescue
        title = "Title wasn't found"
      end
      # render html for youtube video embed
      "<div class='video-title'>#{title}</div><iframe width='420' frameborder='0' height='315'"+
        " src='https://www.youtube-nocookie.com/embed/#{id.to_s}' allowfullscreen></iframe>"
    end

    element 'media', :skip_html => true, :run_globals => false do |buffer|
      result = WikiCloth::error_template 'No media information was retrieved'
      media_url = buffer.get_attribute_by_name "url"
      if media_url
        # Youtube: <media url="http://www.youtube.com/watch?v=[_ID_]">
        # try to retrieve youtube video from media-tag
        youtube_id = get_youtube_video_id media_url
        result = (get_youtube_video youtube_id) if youtube_id
        # Slideshare: <media url="[_SLIDESHARE_URL_]">
        # try to retrieve slideshare slide from media-tag
        result = (get_slideshare_slide media_url) if media_url.match /https*\:\/\/.*slideshare\.net/
      end
      result
    end
  end
end
