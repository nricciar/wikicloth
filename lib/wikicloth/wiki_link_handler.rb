require 'rubygems'
require 'builder'

module WikiCloth

class WikiLinkHandler

  FILE_NAMESPACES = ["datei","image","file","media"]
  CATEGORY_NAMESPACES = ['kategorie','category']
  LANGUAGE_NAMESPACES = ['af','am','ang','ar','arc','ast','az','bn','zh-min-nan','ba','be','be-x-old','bar','bs','br','bg','ca',
	'ceb','cs','co','cy','da','de','dv','et','el','es','eo','eu','fa','fo','fr','fy','ga','gd','gl','gan','ko','hy','hi','hr',
	'io','id','is','it','he','jv','kn','pam','ka','sw','ku','la','lv','lb','lt','hu','mk','mg','ml','mr','arz','ms','nah','nl',
	'ja','no','nn','oc','uz','pap','nds','pl','pt','ksh','ro','qu','ru','sa','sco','sq','scn','simple','sk','sl','sr','sh',
	'fi','sv','tl','ta','th','tg','tr','uk','ur','vi','zh-classical','yi','bat-smg','zh','lo','en','gn','map-bms','pdc','eml',
	'ki','hak','ia','ky','lad','nds-nl','ne','nrm','nov','sm','si','su','kab','te','vec','fiu-vro','wa','war','wuu','zh-yue',
	'diq']

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
    nil
  end

  def section_list(root=nil)
    ret = []
    root = sections[0].children if root.nil?
    root.each do |child|
      ret << child
      unless child.children.empty?
        ret << [section_list(child.children)]
      end
    end
    ret.flatten
  end

  def toc(sections, toc_numbered=false)
    ret = "<table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul>"
    previous_depth = 1
    indices = []
    section_list(sections).each do |section|
      next if section.title.nil?
      if section.depth > previous_depth
        indices[section.depth] = 0 if indices[section.depth].nil?
        indices[section.depth] += 1
        c = section.depth - previous_depth
        c.times { ret += "<ul>" }
        ret += "<li><a href=\"##{section.id}\">#{indices[0..section.depth].compact.join('.') + " " if toc_numbered}#{section.title}</a>"
      elsif section.depth == previous_depth
        indices[section.depth] = 0 if indices[section.depth].nil?
        indices[section.depth] += 1
        ret += "</li><li><a href=\"##{section.id}\">#{indices[0..section.depth].compact.join('.') + " " if toc_numbered}#{section.title}</a>"
      else 
        indices[section.depth] = 0 if indices[section.depth].nil?
        indices[section.depth] += 1
        indices = indices[0..section.depth]
        ret += "</li>" unless previous_depth == 1
        c = previous_depth - section.depth
        c.times { ret += "</ul>" }
        ret += "<li><a href=\"##{section.id}\">#{indices[0..section.depth].compact.join('.') + " " if toc_numbered}#{section.title}</a>"
      end
      previous_depth = section.depth
    end
    ret += "</li>"
    (previous_depth-1).times { ret += "</ul>" }
    "#{ret}</ul></td></tr></table>"
  end

  def external_links
    @external_links ||= []
  end

  def internal_links
    @internal_links ||= []
  end

  def languages
    @languages ||= {}
  end

  def categories
    @categories ||= []
  end

  def find_reference_by_name(n)
    references.each { |r| return r if !r[:name].nil? && r[:name].strip == n }
    return nil
  end

  def reference_index(h)
    references.each_index { |r| return r+1 if references[r] == h }
    return nil
  end

  def categories=(val)
    @categories = val
  end

  def languages=(val)
    @languages = val
  end

  def references=(val)
    @references = val
  end

  def params=(val)
    @params = val
  end

  def external_link(url,text)
    self.external_links << url
    elem.a({ :href => url, :target => "_blank" }) { |x| x << (text.blank? ? url : text) }
  end

  def external_links=(val)
    @external_links = val
  end

  def internal_links=(val)
    @internal_links = val
  end

  def url_for(page)
    "#{page}"
  end

  def link_attributes_for(page)
     { :href => url_for(page) }
  end

  def link_for(page, text)
    self.internal_links << page
    ltitle = !text.nil? && text.blank? ? self.pipe_trick(page) : text
    ltitle = page if text.nil?
    elem.a(link_attributes_for(page)) { |x| x << ltitle.strip }
  end

  def include_resource(resource, options=[])
    if self.params.has_key?(resource)
      self.params[resource]
    else
      @template_cache ||= {}
      if @template_cache[resource]
        @included_templates[resource] += 1
        @template_cache[resource]
      else
        ret = template(resource)
        unless ret.nil?
          @included_templates ||= {}
          @included_templates[resource] ||= 0
          @included_templates[resource] += 1
        end
        @template_cache[resource] = ret
        ret
      end
    end
  end

  def included_templates
    @included_templates ||= {}
  end

  def template(template)
    nil
  end

  def link_for_resource(prefix, resource, options=[])
    ret = ""
    prefix.downcase!
    case
    when FILE_NAMESPACES.include?(prefix)
      ret += wiki_image(resource,options)
    when CATEGORY_NAMESPACES.include?(prefix)
      self.categories << resource
    when LANGUAGE_NAMESPACES.include?(prefix)
      self.languages[prefix] = resource
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
      title = ''
      ffloat = false

      options.each do |x|
        case
        when ["miniatur","thumb","thumbnail","frame","border"].include?(x.strip)
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
      if ["thumb","thumbnail","frame","miniatur"].include?(type)
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
