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
      return @options[:link_handler].function(function_name, params.collect { |p| p.strip }).to_s
    else
      ret = @options[:link_handler].include_resource("#{params[0]}".strip,params[1..-1])
      ret = ret.to_s.gsub(/\{\{\{\s*([A-Za-z0-9]+)\s*\}\}\}/) { |match|
        param_name = $1
        if param_name =~ /^[0-9]+$/
          self.params[match.to_i+1]
        else
          tmp = nil
          self.params.each do |param|
            tmp = param[:value] if param[:name] == param_name
          end
          tmp
        end
      }
      self.data = ret
      ""
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
