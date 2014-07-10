require 'rinku'

READ_MODE = "r:UTF-8"

module Math
  def self.eval(expression)
    allowed_characters = Regexp.escape('+-*/.() ')
    safe_expression = expression.match(/[\d#{allowed_characters}]*/).to_s
    Kernel.eval(safe_expression)
  end
end

module ExtendedString

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def addslashes
    self.gsub(/['"\\\x0]/,'\\\\\0');
  end

  def to_slug
    self.gsub(/\W+/, '-').gsub(/^-+/,'').gsub(/-+$/,'').downcase
  end

  def auto_link
    Rinku.auto_link(to_s)
  end

  def last(n)
    self[-n,n]
  end

  def dump()
    ret = to_s
    delete!(to_s)
    ret
  end

  def smart_split(char)
    ret = []
    tmp = ""
    inside = 0
    to_s.each_char do |x|
      if x == char && inside == 0
        ret << tmp
        tmp = ""
      else
        inside += 1 if x == "[" || x == "{" || x == "<"
        inside -= 1 if x == "]" || x == "}" || x == ">"
        tmp += x
      end
    end
    ret << tmp unless tmp.empty?
    ret
  end

end
