require 'math_parser'

module WikiCloth

class WikiBuffer::Var < WikiBuffer

  def initialize(data="",options={})
    super(data,options)
    self.buffer_type = "var"
    @in_quotes = false
  end

  def skip_html?
    true
  end

  def function_name
    @fname
  end

  def to_s
    if self.is_function?
      ret = default_functions(function_name,params.collect { |p| p.strip })
      ret ||= @options[:link_handler].function(function_name, params.collect { |p| p.strip })
      ret.to_s
    else
      ret = @options[:link_handler].include_resource("#{params[0]}".strip,params[1..-1])
      # template params
      ret = ret.to_s.gsub(/\{\{\{\s*([A-Za-z0-9]+)+(|\|+([^}]+))\s*\}\}\}/) { |match| get_param($1.strip,$3.to_s.strip) }
      # put template at beginning of buffer
      self.data = ret
      ""
    end
  end

  def get_param(name,default=nil)
    ret = nil
    # numbered params
    if name =~ /^[0-9]+$/
      ret = self.params[name.to_i].instance_of?(Hash) ? self.params[name.to_i][:value] : self.params[name.to_i]
    end
    # named params
    self.params.each do |param|
      ret = param[:value] if param[:name] == name
    end
    ret.nil? ? default : ret
  end

  def default_functions(name,params)
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
      begin
        MathParser::Parser.new.parse(params.first)
      rescue RuntimeError
        'Expression error: ' + $!
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
    when "lc"
      params.first.downcase
    when "uc"
      params.first.upcase
    when "ucfirst"
      params.first.capitalize
    when "lcfirst"
      params.first[0,1].downcase + params.first[1,-1]
    end
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
      self.function_name = self.data
      self.data = ""

    # Dealing with variable names within functions
    # and variables
    when current_char == '=' && @in_quotes == false && !is_function?
      self.current_param = self.data
      self.data = ""
      self.name_current_param()

    # End of a template, variable, or function
    when current_char == '}' && previous_char == '}'
      self.data.chop!
      self.current_param = self.data
      self.data = ""
      return false

    else
      self.data += current_char
    end

    return true
  end

end

end
