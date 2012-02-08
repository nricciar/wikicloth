begin
  require 'rubyluabridge'
  DISABLE_LUA = false
rescue LoadError
  DISABLE_LUA = true
end

module WikiCloth
  class LuaElement < HTMLElementAddon

    def self.skip_html?
      true
    end

    def to_s
      if self.options[:disable_lua].nil?
        begin
          self.options[:disable_lua] ||= DISABLE_LUA
          lua_max_lines = self.options[:lua_max_lines] || 1000000
          lua_max_calls = self.options[:lua_max_calls] || 20000

          unless self.options[:disable_lua]
            self.options[:luabridge] = Lua::State.new
            self.options[:luabridge].eval(File.read(File.join(File.expand_path(File.dirname(__FILE__)), "lua", "luawrapper.lua")))
            self.options[:luabridge].eval("wrap = make_wrapper(#{lua_max_lines},#{lua_max_calls})")
          end
        rescue
          self.options[:disable_lua] = true
        end
      end

      unless self.options[:disable_lua]
        begin
          if @function
            case @function[0]
            when "#luaexpr"
              ret = lua_eval("print(#{@function[1]})")
              return ret unless ret.nil?
            else
              error("unknown function '#{@function[0]}'")
            end
          else
            arglist = ''
            self.attributes.each do |key,value|
              arglist += "#{key} = '#{value.addslashes}';"
            end
            ret = lua_eval("#{arglist}\n#{self.content}")
            return ret unless ret.nil?
          end
        rescue => err
          error(err.message)
        end
        super
      else
        return "<!-- lua disabled -->"
      end
    end

    def function(name, params)
      @function = [name, params]
    end

    protected
    def lua_eval(code)
      @options[:luabridge]['chunkstr'] = code
      @options[:luabridge].eval("res, err = wrap(chunkstr, env, hook)")
      unless @options[:luabridge]['err'].nil?
        if @options[:luabridge]['err'] =~ /LOC_LIMIT/
          error("Maximum lines of code limit reached")
        elsif @options[:luabridge]['err'] =~ /RECURSION_LIMIT/
          error("Recursion limit reached")
        else
          error(@options[:luabridge]['err'])
        end
        nil
      else
        @options[:luabridge]['res']
      end
    end

    def error(message)
      self.name = "span"
      self.attributes = { "class" => "error" }
      self.content = message
    end

  end

  Parser.register_html_element("lua", LuaElement)
  Parser.register_var_callback('#luaexpr', LuaElement)
end
