require 'rubygems'
require 'builder'

module WikiCloth

class WikiLinkHandler

  def references
    @references ||= []
  end

  def section_link(section)
    "?section=#{section}"
  end

  def params
    @params ||= {}
  end

  def function(name, params)
    case name
    when "#if"
      params.first.blank? ? params[2] : params[1]
    when "#switch"
      params.length.times do |i|
        temp = params[i].split("=")
        return temp[1].strip if temp[0].strip == params[0] && i != 0
      end
      return ""
    when "#expr"
      Math.eval(params.first)
    when "#ifeq"
      # FIXME: hex should be compared numerically
      if params[0] =~ /^[0-9]+$/ && params[1] =~ /^[0-9]+$/
        params[0].to_i == params[1].to_i ? params[2] : params[3]
      else
        params[0] == params[1] ? params[2] : params[3]
      end
    when "#len"
      params.first.length
    when "#sub"
      params.first[params[1].to_i,params[2].to_i]
    when "#pad"
      case params[3]
      when "right"
        params[0].ljust(params[1].to_i,params[2])
      when "center"
        params[0].center(params[1].to_i,params[2])
      else
        params[0].rjust(params[1].to_i,params[2])
      end
    end
  end

  def toc_children(children)
    ret = "<ul>"
    for child in children
      ret += "<li><a href=\"##{child.id}\">#{child.title}</a>"
      ret += toc_children(child.children) unless child.children.empty?
      ret += "</li>"
    end
    "#{ret}</ul>"
  end

  def toc(sections)
    ret = "<table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul>"
    for section in sections[0].children
      ret += "<li><a href=\"##{section.id}\">#{section.title}</a>"
      ret += toc_children(section.children) unless section.children.empty?
      ret += "</li>"
    end
    "#{ret}</ul></td></tr></table>"
  end

  def external_links
    @external_links ||= []
  end

  def find_reference_by_name(n)
    references.each { |r| return r if !r[:name].nil? && r[:name].strip == n }
    return nil
  end

  def reference_index(h)
    references.each_index { |r| return r+1 if references[r] == h }
    return nil
  end

  def references=(val)
    @references = val
  end

  def params=(val)
    @params = val
  end

  def external_link(url,text)
    self.external_links << url
    elem.a({ :href => url }) { |x| x << (text.blank? ? url : text) }
  end

  def external_links=(val)
    @external_links = val
  end

  def url_for(page)
    "javascript:void(0)"
  end

  def link_attributes_for(page)
     { :href => url_for(page) }
  end

  def link_for(page, text)
    ltitle = !text.nil? && text.blank? ? self.pipe_trick(page) : text
    ltitle = page if text.nil?
    elem.a(link_attributes_for(page)) { |x| x << ltitle.strip }
  end

  def include_resource(resource, options=[])
    if self.params.has_key?(resource)
      self.params[resource]
    else
      # FIXME: hack to keep template loops from raising havoc
      @include_count ||= 0
      @include_count += 1
      raise "Page reached maximum number of includes [1000] (possible template loop?)" if @include_count > 100

      ret = template(resource,options)
      unless ret.nil?
        @included_templates ||= {}
        @included_templates[resource] ||= 0
        @included_templates[resource] += 1
      end
    end
  end

  def included_templates
    @included_templates ||= {}
  end

  def template(template,options=[])
    nil
  end

  def link_for_resource(prefix, resource, options=[])
    ret = ""
    prefix.downcase!
    case
    when ["image","file","media"].include?(prefix)
      ret += wiki_image(resource,options)
    else
      title = options[0] ? options[0] : "#{prefix}:#{resource}"
      ret += link_for("#{prefix}:#{resource}",title)
    end
    ret
  end

  protected
  def pipe_trick(page)
    t = page.split(":")
    t = t[1..-1] if t.size > 1
    return t.join("").split(/[,(]/)[0]
  end

  # this code needs some work... lots of work
  def wiki_image(resource,options)
      pre_img = ''
      post_img = ''
      css = []
      loc = "right"
      type = nil
      w = 180
      h = nil
      title = nil
      ffloat = false

      options.each do |x|
        case
        when ["thumb","thumbnail","frame","border"].include?(x.strip)
          type = x.strip
        when ["left","right","center","none"].include?(x.strip)
          ffloat = true
          loc = x.strip
        when x.strip =~ /^([0-9]+)\s*px$/
          w = $1
          css << "width:#{w}px"
        when x.strip =~ /^([0-9]+)\s*x\s*([0-9]+)\s*px$/
          w = $1
          css << "width:#{w}px"
          h = $2
          css << "height:#{h}px"
        else
          title = x.strip
        end
      end
      css << "float:#{loc}" if ffloat == true
      css << "border:1px solid #000" if type == "border"

      sane_title = title.nil? ? "" : title.gsub(/<\/?[^>]*>/, "")
      if type == "thumb" || type == "thumbnail" || type == "frame"
        pre_img = '<div class="thumb t' + loc + '"><div class="thumbinner" style="width: ' + w.to_s +
            'px;"><a href="" class="image" title="' + sane_title + '">'
        post_img = '</a><div class="thumbcaption">' + title + '</div></div></div>'
      end
      "#{pre_img}<img src=\"#{resource}\" alt=\"#{sane_title}\" title=\"#{sane_title}\" style=\"#{css.join(";")}\" />#{post_img}"
  end

  def elem
    Builder::XmlMarkup.new
  end

end

end
