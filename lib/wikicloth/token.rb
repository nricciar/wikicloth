# not actually used by wikicloth atm
module WikiCloth

  class Token
    OpenRes      = 1
    CloseRes     = 2
    OpenLink     = 3
    CloseLink    = 4
    Heading      = 5
    Word         = 6
    NewLine      = 7
    OpenElement  = 8
    CloseElement = 9
    Equals       = 10
    Quote        = 11
    BeginComment = 12
    EndComment   = 13
    BeginTable   = 14
    EndTable     = 15
    Pipe         = 16
    BoldItalic   = 17
    ListItem     = 18
    Signature    = 19
    Space        = 20
    Colon        = 21
    End          = 22

    attr_accessor :kind
    attr_accessor :value

    def initialize
      @kind = nil
      @value = nil
    end

    def unknown?
      @kind.nil?
    end
  end

end
