class Object
  module InstanceExecHelper; end
  include InstanceExecHelper
  def instance_exec(*args, &block)
    begin
      old_critical, Thread.critical = Thread.critical, true
      n = 0
      n += 1 while respond_to?(mname="__instance_exec#{n}")
      InstanceExecHelper.module_eval{ define_method(mname, &block) }
    ensure
      Thread.critical = old_critical
    end
    begin
      ret = send(mname, *args)
    ensure
      InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
    end
    ret
  end
end

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

  def to_slug
    self.gsub(/\W+/, '-').gsub(/^-+/,'').gsub(/-+$/,'').downcase
  end

  def auto_link
    url_check = Regexp.new( '(^|[\n ])([\w]+?://[\w]+[^ \"\r\n\t<]*)', Regexp::MULTILINE | Regexp::IGNORECASE )
    www_check = Regexp.new( '(^|[\n ])((www)\.[^ \"\t\n\r<]*)', Regexp::MULTILINE | Regexp::IGNORECASE )
    self.gsub!(url_check, '\1<a href="\2">\2</a>')
    self.gsub!(www_check, '\1<a href="http://\2">\2</a>')
    to_s
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
