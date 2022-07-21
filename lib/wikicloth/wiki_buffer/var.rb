require 'expression_parser'
require 'digest/md5'
require 'uri'

module WikiCloth

class WikiBuffer::Var < WikiBuffer

  def initialize(data="",options={})
    super(data,options)
    self.buffer_type = "var"
    @in_quotes = false
    @tag_start = true
    @tag_size = 2
    @close_size = 2
    @fname = nil
  end

  def tag_size
    @tag_size
  end

  def tag_size=(val)
    @tag_size = val
  end

  def skip_links?
    false
  end

  def skip_html?
    false
  end

  def tag_start
    @tag_start
  end

  def tag_start=(val)
    @tag_start = val
  end

  def function_name
    @fname.nil? ? nil : @fname.strip
  end

  def to_html
    return "" if will_not_be_rendered

    if self.is_function?
      if Extension.function_exists?(function_name)
        return Extension.functions[function_name][:klass].new(@options).instance_exec( params.collect { |p| p.strip }, &Extension.functions[function_name][:block] ).to_s
      end
      ret = default_functions(function_name,params.collect { |p| p.strip })
      ret ||= @options[:link_handler].function(function_name, params.collect { |p| p.strip })
      ret.to_s
    elsif self.is_param?
      ret = nil
      @options[:buffer].buffers.reverse.each do |b|
        ret = b.get_param(params[0],params[1]) if b.instance_of?(WikiBuffer::HTMLElement) && b.element_name == "template"
        break unless ret.nil?
      end
      ret.to_s
    else
      # put template at beginning of buffer
      template_stack = @options[:buffer].buffers.collect { |b| b.get_param("__name") if b.instance_of?(WikiBuffer::HTMLElement) && 
        b.element_name == "template" }.compact
      if template_stack.last == params[0]
        debug_tree = @options[:buffer].buffers.collect { |b| b.debug }.join("-->")
        "<span class=\"error\">#{I18n.t('template loop detected', :tree => debug_tree)}</span>"
      else
        key = params[0].to_s.strip
        key_options = params[1..-1].collect { |p| p.is_a?(Hash) ? { :name => p[:name].strip, :value => p[:value].strip } : p.strip }
        key_options ||= []
        key_digest = Digest::MD5.hexdigest(key_options.to_a.sort {|x,y| (x.is_a?(Hash) ? x[:name] : x) <=> (y.is_a?(Hash) ? y[:name] : y) }.inspect)

        return @options[:params][key] if @options[:params].has_key?(key)
        # if we have a valid cache fragment use it
        return @options[:cache][key][key_digest] unless @options[:cache].nil? || @options[:cache][key].nil? || @options[:cache][key][key_digest].nil?

        ret = @options[:link_handler].include_resource(key,key_options).to_s

        ret.gsub!(/<!--.*?-->/m,"") unless ret.frozen?
        count = 0
        tag_attr = key_options.collect { |p|
          if p.instance_of?(Hash)
            "#{p[:name]}=\"#{p[:value].gsub(/"/,'&quot;')}\""
          else
            count += 1
            "#{count}=\"#{p.gsub(/"/,'&quot;')}\""
          end
        }.join(" ")

        self.data = ret.blank? ? "" : "<template __name=\"#{key}\" __hash=\"#{key_digest}\" #{tag_attr}>#{ret}</template>"
        ""
      end
    end
  end

  def will_not_be_rendered
    @options[:buffer].buffers.reverse.each do |buffer|
      if buffer.instance_of?(WikiBuffer::Var) && buffer.is_function?
        return true if buffer.function_name == "#if" && buffer.params.size == 2 && buffer.params[0].strip.blank?
        return true if buffer.function_name == "#if" && buffer.params.size == 3 && !buffer.params[0].strip.blank?
      end
    end
    false
  end

  def default_functions(name,params)
    case name
    when "#if"
      params.first.blank? ? params[2] : params[1]
    when "#switch"
      match = params.first
      default = nil
      for p in params[1..-1]
        temp = p.split("=")
        if p !~ /=/ && temp.length == 1 && p == params.last
          return p
        elsif temp.instance_of?(Array) && temp.length > 0
          test = temp.first.strip
          default = temp[1..-1].join("=").strip if test == "#default"
          return temp[1..-1].join("=").strip if test == match || (test == "none" && match.blank?)
        end
      end
      default.nil? ? "" : default
    when "#expr"
      begin
        ExpressionParser::Parser.new.parse(params.first)
      rescue RuntimeError
        I18n.t('expression error', :error => $!)
      end
    when "#ifexpr"
      val = false
      begin
        val = ExpressionParser::Parser.new.parse(params.first)
      rescue RuntimeError
      end
      if val
        params[1]
      else
        params[2]
      end
    when "#ifeq"
      if params[0] =~ /^[0-9A-Fa-f]+$/ && params[1] =~ /^[0-9A-Fa-f]+$/
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
    when "#iferror"
      params.first =~ /error/ ? params[1] : params[2]
    when "#capture"
      @options[:params][params.first] = params[1]
      ""
    when "urlencode"
      URI.encode_www_form_component(params.first)
    when "lc"
      params.first.downcase
    when "uc"
      params.first.upcase
    when "ucfirst"
      params.first.capitalize
    when "lcfirst"
      params.first[0,1].downcase + params.first[1..-1].to_s
    when "anchorencode"
      params.first.gsub(/\s+/,'_')
    when "plural"
      begin
        expr_value = ExpressionParser::Parser.new.parse(params.first)
        expr_value.to_i == 1 ? params[1] : params[2]
      rescue RuntimeError
        I18n.t('expression error', :error => $!)
      end
    when "ns"
      values = {
        "" => "", "0" => "",
        "1" => localise_ns("Talk"), "talk" => localise_ns("Talk"),
        "6" => localise_ns("File"), "file" => localise_ns("File"), "image" => localise_ns("File"),
        "10" => localise_ns("Template"), "template" => localise_ns("Template"),
        "14" => localise_ns("Category"), "category" => localise_ns("Category"),
        "-1" => localise_ns("Special"), "special" => localise_ns("Special"),
        "12" => localise_ns("Help"), "help" => localise_ns("Help"),
        "-2" => localise_ns("Media"), "media" => localise_ns("Media") }

      values[localise_ns(params.first,:en).gsub(/\s+/,'_').downcase]
    when "#language"
      WikiNamespaces.language_name(params.first)
    when "#tag"
      return "" if params.empty?
      elem = Builder::XmlMarkup.new
      return elem.tag!(params.first) if params.length == 1
      return elem.tag!(params.first) { |e| e << params.last } if params.length == 2
      tag_attrs = {}
      params[1..-2].each do |attr|
        tag_attrs[$1] = $2 if attr =~ /^\s*([\w]+)\s*=\s*"(.*)"\s*$/
      end
      elem.tag!(params.first,tag_attrs) { |e| e << params.last }
    when "debug"
      ret = nil
      case params.first
      when "param"
        @options[:buffer].buffers.reverse.each do |b|
          if b.instance_of?(WikiBuffer::HTMLElement) && b.element_name == "template"
             ret = b.get_param(params[1])
          end
        end
        ret
      when "buffer"
        ret = "<pre>"
        buffer = @options[:buffer].buffers
        buffer.each do |b|
          ret += " --- #{b.class}"
          ret += b.instance_of?(WikiBuffer::HTMLElement) ? " -- #{b.element_name}\n" : " -- #{b.data}\n"
        end
        "#{ret}</pre>"
      end
    end
  end

  def localise_ns(name,lang=nil)
    WikiNamespaces.localise_ns(name,lang)
  end

  def is_param?
    @tag_size == 3 ? true : false
  end

  def is_function?
    self.function_name.nil? || self.function_name.blank? ? false : true
  end

  protected
  def function_name=(val)
    @fname = val
  end

  def new_char()
    case
    when current_char == '|' && @in_quotes == false
      self.current_param = self.data
      self.data = ""
      self.params << ""

    # Start of either a function or a namespace change
    when current_char == ':' && @in_quotes == false && self.params.size <= 1
      if self.data.blank? || self.data.include?(":")
	self.data << current_char
      else
        self.function_name = self.data
        self.data = ""
      end

    # Dealing with variable names within functions
    # and variables
    when current_char == '=' && @in_quotes == false && !is_function?
      self.current_param = self.data
      self.data = ""
      self.name_current_param()

    # End of a template, variable, or function
    when current_char == '}' && previous_char == '}'
      if @close_size == @tag_size
        self.data.chop!
        self.current_param = self.data
        self.data = ""
        return false
      else
        @close_size += 1
      end

    else
      self.data << current_char
      if @tag_start
        # FIXME: template params and templates colliding
        if @tag_size > 3
          if @tag_size == 5
            @options[:buffer].buffers << WikiBuffer::Var.new(self.data,@options)
            @options[:buffer].buffers[-1].tag_start = false
            self.data = ""
            @tag_size = 3
            return true
          end
        end
        @tag_start = false
      end
    end

    return true
  end

end

end
