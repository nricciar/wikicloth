# not actually used by wikicloth atm
module WikiCloth

  class Lexer

    def initialize(input)
      @input = input
      @return_previous_token = false
    end

    def get_next_token
      if @return_previous_token
	@return_previous_token = false
	return @previous_token
      end

      token = Token.new
      prepend_input = nil

      case @input
      when /\A\s+/
        token.kind = Token::Space
      when /\A:/
        token.kind = Token::Colon
      when /\A([']{2,5})/
        token.kind = Token::BoldItalic
      when /\A\n([*]{1,})/
        token.kind = Token::ListItem
      when /\A~~~~/
        token.kind = Token::Signature
      when /\A<!--/
        token.kind = Token::BeginComment
      when /\A-->/
        token.kind = Token::EndComment
      when /\A[\w\(\)\.\%;\#\-\/,'&\*~]+/
        # swallowed bold/italic
        if $&[-2,2] == "''"
          prepend_input = "''"
          token.value = $&[0..-3]
        elsif $&[-3,3] == "'''"
          prepend_input = "'''"
          token.value = $&[0..-4]
        elsif $&[-5,5] == "'''''"
          prepend_input = "'''''"
          token.value = $&[0..-6]
        # accidently swallowed closing comment
        elsif $&[-2,2] == "--" && $'[0,1] == '>'
          prepend_input = '--'
          token.value = $&[0..-3]
        else
          token.value = $&
        end
        token.kind = Token::Word
      when /\A\{\|/
        token.kind = Token::BeginTable
      when /\A\|\}/
        token.kind = Token::EndTable
      when /\A\|/
        token.kind = Token::Pipe
      when /\A=/
        token.kind = Token::Equals
      when /\A"/
        token.kind = Token::Quote
      when /\A\n/
        token.kind = Token::NewLine
      when /\A\{\{/
        token.kind = Token::OpenRes
      when /\A\}\}/
        token.kind = Token::CloseRes
      when /\A\[\[/
        token.kind = Token::OpenLink
        token.value = $&
      when /\A\]\]/
        token.kind = Token::CloseLink
        token.value = $&
      when /\A\[/
        token.kind = Token::OpenLink
        token.kind = $&
      when /\A\]/
        token.kind = Token::CloseLink
        token.kind = $&
      when /\A\<\s*\//
        token.kind = Token::OpenElement
      when /\A\</
        token.kind = Token::OpenElement
      when /\A\>/
        token.kind = Token::CloseElement
      when ''
        token.kind = Token::End
      end
      token.value ||= $&

      raise "Unknown token #{@input}" if token.unknown?
      @input = "#{prepend_input}#{$'}"

      @previous_token = token
      token
    end

    def revert
      @return_previous_token = true
    end
  end

end
