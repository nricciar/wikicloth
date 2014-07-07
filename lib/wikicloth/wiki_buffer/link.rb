module WikiCloth

class WikiBuffer::Link < WikiBuffer

  def initialize(data="",options={})
    super(data,options)
    @in_quotes = false
    @checktrailing = false
  end

  def internal_link
    @internal_link ||= false
  end

  def to_html
    link_handler = @options[:link_handler]
    unless self.internal_link || params[0].strip !~ /^\s*((([a-z]+):\/\/|mailto:)|[\?\/])(.*)/
      if $1.downcase == "mailto:"
        return link_handler.external_link("#{params[0]}".strip, $4)
      elsif params.length > 1
        return link_handler.external_link("#{params[0]}".strip, params.last.strip)
      else
        return link_handler.external_link("#{params[0]}".strip)
      end
    else
      case
      when params[0] =~ /^:(.*)/
        return link_handler.link_for(params[0],params[1])
      when params[0] =~ /^\s*([^\]\s:]+)\s*:(.*)$/
        return link_handler.link_for_resource($1,$2,params[1..-1])
      else
        return "" if params[0].blank? && params[1].blank?
        return link_handler.link_for(params[0],params[1])
      end
    end
  end

  def eof()
    self.current_param = self.data
  end

  protected
  def internal_link=(val)
    @internal_link = (val == true ? true : false)
  end

  def new_char()
    case
    when @checktrailing && current_char !~ /\w/
      self.current_param = self.data
      self.data = current_char == '{' ? "" : current_char
      return false

    # check if this link is internal or external
    when previous_char.blank? && current_char == '['
      self.internal_link = true

    # Marks the beginning of another paramater for
    # the current object
    when current_char == '|' && self.internal_link == true && @in_quotes == false
      self.current_param = self.data
      self.data = ""
      self.params << ""

    # URL label
    when current_char == ' ' && self.internal_link == false && params[1].nil? && !self.data.blank?
      self.current_param = self.data
      self.data = ""
      self.params << ""

    # end of link
    when current_char == ']' && ((previous_char == ']' && self.internal_link == true) || self.internal_link == false)  && @in_quotes == false
      self.current_param = self.data
      if self.internal_link == true
        self.data.chop!.rstrip!
        self.params << "" unless self.params.size > 1
        @checktrailing = true
      else
        self.data = ""
        return false
      end
    else
      self.data += current_char unless current_char == ' ' && self.data.blank?
    end

    return true
  end

end

end
