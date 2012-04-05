require 'rexml/document'

module WikiCloth

class WikiBuffer::HTMLElement < WikiBuffer

  ALLOWED_ELEMENTS = ['a','b','i','img','div','span','sup','sub','strike','s','u','font','big','ref','tt','del',
	'small','blockquote','strong','pre','code','references','ol','li','ul','dd','dt','dl','center',
	'h1','h2','h3','h4','h5','h6','p','table','tr','td','th','tbody','thead','tfoot']
  ALLOWED_ATTRIBUTES = ['src','id','name','style','class','href','start','value','colspan','align','border',
        'cellpadding','cellspacing','name','valign','color','rowspan','nowrap','title','rel','for']
  ESCAPED_TAGS = [ 'nowiki','pre','code' ]
  SHORT_TAGS = [ 'meta','br','hr']
  NO_NEED_TO_CLOSE = ['li','p'] + SHORT_TAGS
  DISABLE_GLOBALS_FOR = ESCAPED_TAGS

  def initialize(d="",options={},check=nil)
    super("",options)
    self.buffer_type = "Element"
    @in_quotes = false
    @in_single_quotes = false
    @start_tag = 1
    @tag_check = check
  end

  def debug
    case self.element_name
    when "template"
      self.get_param("__name")
    else
      ret = self.class.to_s + "["
      ret += self.element_name
      tmp = self.get_param("id")
      ret += tmp.nil? ? "" : "##{tmp}"
      ret + "]"
    end
  end

  def skip_html?
    return Extension.skip_html?(self.element_name) if Extension.element_exists?(self.element_name)
    DISABLE_GLOBALS_FOR.include?(self.element_name) ? true : false
  end

  def run_globals?
    return false if self.in_template? && self.element_name == "noinclude"
    return false if !self.in_template? && self.element_name == "includeonly"
    return Extension.run_globals?(self.element_name) if Extension.element_exists?(self.element_name)
    return DISABLE_GLOBALS_FOR.include?(self.element_name) ? false : true
  end

  def to_html
    if NO_NEED_TO_CLOSE.include?(self.element_name)
      return "<#{self.element_name} />" if SHORT_TAGS.include?(self.element_name)
      return "</#{self.element_name}><#{self.element_name}>" if @tag_check == self.element_name
    end

    if ESCAPED_TAGS.include?(self.element_name)
      # remove empty first line
      self.element_content = $1 if self.element_content =~ /^\s*\n(.*)$/m
      # escape all html inside this element
      self.element_content = self.element_content.gsub('<','&lt;').gsub('>','&gt;')
      # hack to fix <code><nowiki> nested mess
      self.element_content = self.element_content.gsub(/&lt;[\/]*\s*nowiki\s*&gt;/,'')
    end

    case self.element_name
    when "template"
      @options[:link_handler].cache({ :name => self.element_attributes["__name"], :content => self.element_content, :md5 => self.element_attributes["__hash"] })
      return self.element_content
    when "noinclude"
      return self.in_template? ? "" : self.element_content
    when "includeonly"
      return self.in_template? ? self.element_content : ""
    when "nowiki"
      return self.element_content
    when "a"
      if self.element_attributes['href'] =~ /:\/\//
        return @options[:link_handler].external_link(self.element_attributes['href'], self.element_content)
      elsif self.element_attributes['href'].nil? || self.element_attributes['href'] =~ /^\s*([\?\/])/
        # if a element has no href attribute, or href starts with / or ?
        return elem.tag!(self.element_name, self.element_attributes) { |x| x << self.element_content }
      end
    else
      if Extension.element_exists?(self.element_name)
        return Extension.html_elements[self.element_name][:klass].new(@options).instance_exec( self, &Extension.html_elements[self.element_name][:block] ).to_s
      end
    end

    tmp = elem.tag!(self.element_name, self.element_attributes) { |x| x << self.element_content }
    unless ALLOWED_ELEMENTS.include?(self.element_name)
      tmp.gsub!(/[\-!\|&"\{\}\[\]]/) { |r| self.escape_char(r) }
      return tmp.gsub('<', '&lt;').gsub('>', '&gt;')
    end
    tmp
  end

  def get_attribute_by_name(name)
    params.each { |p| return p[:value] if p.kind_of?(Hash) && p[:name] == name }
    nil
  end

  def element_attributes
    attr = {}
    params.each { |p| attr[p[:name]] = p[:value] if p.kind_of?(Hash) }
    if ALLOWED_ELEMENTS.include?(self.element_name.strip.downcase)
      attr.delete_if { |key,value| !ALLOWED_ATTRIBUTES.include?(key.strip) }
    end
    return attr
  end

  def element_name
    @ename ||= ""
  end

  def element_content
    @econtent ||= ""
  end

  protected

  def escape_char(c)
    c = case c
    when '-' then '&#45;'
    when '!' then '&#33;'
    when '|' then '&#124;'
    when '&' then '&amp;'
    when '"' then '&quot;'
    when '{' then '&#123;'
    when '}' then '&#125;'
    when '[' then '&#91;'
    when ']' then '&#93;'
    when '*' then '&#42;'
    when '#' then '&#35;'
    when ':' then '&#58;'
    when ';' then '&#59;'
    when "'" then '&#39;'
    when '=' then '&#61;'
    else
      c
    end
    return c
  end

  def elem
    Builder::XmlMarkup.new
  end

  def element_name=(val)
    @ename = val
  end

  def element_content=(val)
    @econtent = val
  end

  def in_quotes?
    @in_quotes || @in_single_quotes ? true : false
  end

  def new_char()
    case
    # tag name
    when @start_tag == 1 && current_char == ' '
      self.element_name = self.data.strip.downcase
      self.data = ""
      @start_tag = 2

    # tag is closed <tag/> no attributes
    when @start_tag == 1 && previous_char == '/' && current_char == '>'
      self.data.chop!
      self.element_name = self.data.strip.downcase
      self.data = ""
      @start_tag = 0
      return false

    # open tag
    when @start_tag == 1 && previous_char != '/' && current_char == '>'
      self.element_name = self.data.strip.downcase
      self.data = ""
      @start_tag = 0
      return false if SHORT_TAGS.include?(self.element_name)
      return false if self.element_name == @tag_check && NO_NEED_TO_CLOSE.include?(self.element_name)

    # new tag attr
    when @start_tag == 2 && current_char == ' ' && self.in_quotes? == false
      self.current_param = self.data
      self.data = ""
      self.params << ""

    # tag attribute name
    when @start_tag == 2 && current_char == '=' && self.in_quotes? == false
      self.current_param = self.data
      self.data = ""
      self.name_current_param()

    # tag is now open
    when @start_tag == 2 && previous_char != '/' && current_char == '>'
      self.current_param = self.data
      self.data = ""
      @start_tag = 0
      return false if SHORT_TAGS.include?(self.element_name)
      return false if self.element_name == @tag_check && NO_NEED_TO_CLOSE.include?(self.element_name)

    # tag is closed <example/>
    when @start_tag == 2 && previous_char == '/' && current_char == '>'
      self.current_param = self.data.chop
      self.data = ""
      @start_tag = 0
      return false

    # in quotes
    when @start_tag == 2 && current_char == "'" && previous_char != '\\' && !@in_quotes
      @in_single_quotes = !@in_single_quotes

    # in quotes
    when @start_tag == 2 && current_char == '"' && previous_char != '\\' && !@in_single_quotes
      @in_quotes = !@in_quotes

    # start of a closing tag
    when @start_tag == 0 && previous_char == '<' && current_char == '/'
      self.element_content += self.data.chop
      self.data = ""
      @start_tag = 5

    when @start_tag == 5 && (current_char == '>' || current_char == ' ') && !self.data.blank?
      self.data = self.data.strip.downcase
      if self.data == self.element_name
        self.data = ""
        return false
      else
        if @tag_check == self.data && NO_NEED_TO_CLOSE.include?(self.element_name)
          self.data = "</#{self.data}>"
          return false
        else
          self.element_content += skip_html? ? "</#{self.data}>" : "&lt;/#{self.data}&gt;"
          @start_tag = 0
          self.data = ""
        end
      end

    else
      if @start_tag == 0 && ESCAPED_TAGS.include?(self.element_name)
        self.data << self.escape_char(current_char)
      else
        self.data << current_char
      end
    end
    return true
  end

end

end
