module WikiCloth
class WikiBuffer

  def initialize(data="",options={})
    @options = options
    @options[:buffer] ||= self
    self.data = data
    self.buffer_type = nil
    @section_count = 0
    @buffers ||= [ ]
    @buffers << self
    @list_data = []
    @check_new_tag = false
    @indent = nil
    @previous_line_empty = false
    @paragraph_open = false
  end

  def debug
    self.params[0].blank? ? self.class.to_s : self.params[0]
  end

  def run_globals?
    true
  end

  def buffers
    @buffers
  end

  def skip_html?
    false
  end

  def skip_links?
    false
  end

  def data
    @data ||= ""
  end

  def params
    @params ||= [ "" ]
  end

  def get_param(name,default=nil)
    ret = nil
    self.params.each do |param|
      ret = param[:value] if param.instance_of?(Hash) && param[:name] == name
    end
    ret.nil? ? default : ret
  end

  def in_template?
    @options[:buffer].buffers.each do |b|
      return true if b.instance_of?(WikiBuffer::HTMLElement) && b.element_name == "template"
    end
    false
  end

  def buffer_type
    @buffer_type
  end

  def to_s
    self.params.join("\n") + (@list_data.empty? ? "" : render_list_data()) + (@paragraph_open ? "</p>" : "")
  end

  def check_globals()
    return false if self.class != WikiBuffer

    if previous_char == "\n" || previous_char == ""
      if @indent == @buffers[-1].object_id && current_char != " "
        @indent = nil
        # close pre tag
        cc_temp = current_char
        "</pre>\n".each_char { |c| self.add_char(c) }
        # get the parser back on the right track
        "\n#{cc_temp}".each_char { |c| @buffers[-1].add_char(c) }
        return true
      end
      if current_char == " " && @indent.nil? && ![WikiBuffer::HTMLElement,WikiBuffer::Var].include?(@buffers[-1].class)
        "\n<pre> ".each_char { |c| @buffers[-1].add_char(c) }
        @indent = @buffers[-1].object_id
        return true
      end
    end

    if @buffers[-1].run_globals?
      # new html tag
      if @check_new_tag == true && current_char =~ /([a-z])/ && !@buffers[-1].skip_html?
        @buffers[-1].data.chop!
        parent = @buffers[-1].element_name if @buffers[-1].class == WikiBuffer::HTMLElement
        @buffers << WikiBuffer::HTMLElement.new("",@options,parent)
      end
      @check_new_tag = current_char == '<' ? true : false

      # global
      case
      # start variable
      when previous_char == '{' && current_char == '{'
        if @buffers[-1].instance_of?(WikiBuffer::Var) && @buffers[-1].tag_start == true
          @buffers[-1].tag_size += 1
        else
          @buffers[-1].data.chop! if @buffers[-1].data[-1,1] == '{'
          @buffers << WikiBuffer::Var.new("",@options)
        end
        return true

      # start link
      when current_char == '[' && previous_char != '[' && !@buffers[-1].skip_links?
        @buffers << WikiBuffer::Link.new("",@options)
        return true

      # start table
      when previous_char == '{' && current_char == "|"
        @buffers[-1].data.chop!
        @buffers << WikiBuffer::Table.new("",@options)
        return true

      end
    end

    return false
  end

  def add_word(w)
    self.previous_char = w[-2,1]
    self.current_char = w[-1,1]
    @buffers[-1].data += w
  end

  def eof()
    return if @buffers.size == 1

    if self.class == WikiBuffer
      while @buffers.size > 1
        @buffers[-1].eof()
        tmp = @buffers.pop
        @buffers[-1].data += tmp.to_s
        unless tmp.data.blank?
          tmp.data.each_char { |x| self.add_char(x) }
        end
      end
    else
      # default cleanup tasks
    end
  end

  def add_char(c)
    self.previous_char = self.current_char
    self.current_char = c

    if self.check_globals() == false
      case
      when @buffers.size == 1
        return self.new_char()
      when @buffers[-1].add_char(c) == false && self.class == WikiBuffer
        tmp = @buffers.pop
        @buffers[-1].data += tmp.to_s
        # any data left in the buffer we feed into the parent
        unless tmp.data.blank?
          tmp.data.each_char { |x| self.add_char(x) }
        end
      end
    end
  end

  protected
  # only executed in the default state
  def new_char()
    case
    when current_char == "\n"
      # Underline, and Strikethrough
      if @options[:extended_markup] == true
        self.data.gsub!(/---([^-]+)---/,"<strike>\\1</strike>")
        self.data.gsub!(/_([^_]+)_/,"<u>\\1</u>")
      end

      # Magic Words
      self.data.gsub!(/__([A-Z]+)__/) { |r|
        case $1
        when "TOC"
          @options[:link_handler].toc(@options[:sections])
        else
          ""
        end
      }

      # Horizontal Rule
      self.data.gsub!(/^([-]{4,})/) { |r| "<hr />" }

      # Bold, Italic
      self.data.gsub!(/([\']{2,5})(.*?)(\1)/) { |r|
        tmp = "<i>#{$2}</i>" if $1.length == 2
        tmp = "<b>#{$2}</b>" if $1.length == 3
        tmp = "<b>'#{$2}'</b>" if $1.length == 4
        tmp = "<b><i>#{$2}</i></b>" if $1.length == 5
        tmp
      }

      # Lists
      tmp = ''
      self.data.each_line do |line|
        if line =~ /^([#\*:;]+)/
          # Add current line to list data
          @list_data << line
        else
          # render list if list data was just closed
          tmp += render_list_data() unless @list_data.empty?
          tmp += line
        end
      end
      self.data = tmp

      # Headings
      is_heading = false
      self.data.gsub!(/^([=]{1,6})\s*(.*?)\s*(\1)/) { |r|
        is_heading = true
        (@paragraph_open ? "</p>" : "") + "<h#{$1.length}>#{$2}</h#{$1.length}>"
      }

      # Paragraphs
      if is_heading
        @paragraph_open = false
      else
        if self.data =~ /^\s*$/ && @paragraph_open && @list_data.empty?
          self.data = "</p>#{self.data}"
          @paragraph_open = false
        else
          if self.data !~ /^\s*$/
            self.data = "<p>#{self.data}" and @paragraph_open = true unless @paragraph_open
          end
        end
      end

      self.params << self.data.auto_link
      self.data = ""
    else
      self.data += current_char
    end
    return true
  end

  def name_current_param()
    params[-1] = { :value => "", :name => params[-1] } unless params[-1].kind_of?(Hash) || params[-1].nil?
  end

  def current_param=(val)
    unless self.params[-1].nil? || self.params[-1].kind_of?(String)
      self.params[-1][:value] = val
    else
      self.params[-1] = val
    end
  end

  def params=(val)
    @params = val
  end

  def buffer_type=(val)
    @buffer_type = val
  end

  def data=(val)
    @data = val
  end

  def current_char=(val)
    @current_char = val
  end

  def current_char
    @current_char ||= ""
  end

  def previous_char=(val)
    @previous_char = val
  end

  def previous_char
    @previous_char
  end

  def current_line=(val)
    @current_line = val
  end

  def current_line
    @current_line ||= ""
  end

  def render_list_data()
    ret = ""
    depth = 0
    peices = ""

    @list_data.each do |l|
      if l =~ /^([#\*:;]+)\s*(.*)$/
        peices = $1
        content = $2
        if peices.length > depth
          while peices.length > depth
            ret += "<#{list_tag_for(peices[depth,1])}><#{list_inner_tag_for(peices[depth,1])}>"
            depth += 1
          end
        elsif peices.length == depth
          ret += "</#{list_inner_tag_for(peices[depth-1,1])}><#{list_inner_tag_for(peices[depth-1,1])}>"
        else
          while peices.length < depth
            depth -= 1
            ret += "</#{list_inner_tag_for(peices[depth-1,1])}></#{list_tag_for(peices[depth-1,1])}><#{list_inner_tag_for(peices[depth-1,1])}>"
          end
        end
        ret += "#{content}"
      end
    end
    while depth > 0
      depth -= 1
      ret += "</#{list_inner_tag_for(peices[depth,1])}></#{list_tag_for(peices[depth,1])}>"
    end
    @list_data = []
    ret + "\n"
  end

  def list_tag_for(tag)
    case tag
    when "#" then "ol"
    when "*" then "ul"
    when ";" then "dl"
    when ":" then "dl"
    end
  end

  def list_inner_tag_for(tag)
    case tag
    when "#" then "li"
    when "*" then "li"
    when ";" then "dt"
    when ":" then "dd"
    end
  end

end

end

require File.join(File.expand_path(File.dirname(__FILE__)), "wiki_buffer", "html_element")
require File.join(File.expand_path(File.dirname(__FILE__)), "wiki_buffer", "table")
require File.join(File.expand_path(File.dirname(__FILE__)), "wiki_buffer", "var")
require File.join(File.expand_path(File.dirname(__FILE__)), "wiki_buffer", "link")
