begin
  require 'rubyluabridge'
  DISABLE_LUA = false
rescue LoadError
  DISABLE_LUA = true
end

module WikiCloth
  class LuaExtension < Extension

    element 'lua', :skip_html => true, :run_globals => false do |buffer|
      init_lua
      unless @options[:disable_lua]
        begin
          arglist = ''
          buffer.element_attributes.each do |key,value|
            arglist += "#{key} = '#{value.addslashes}';"
          end
          lua_eval("#{arglist}\n#{buffer.element_content}").to_s
        rescue => err
          "<span class=\"error\">#{err.message}</span>"
        end
      else
        return "<!-- #{I18n.t('lua disabled')} -->"
      end
    end

    function '#luaexpr' do |params|
      init_lua
      unless @options[:disable_lua]
        begin
          lua_eval("print(#{params.first})").to_s
        rescue => err
          "<span class=\"error\">#{err.message}</span>"
        end
      else
        return "<!-- #{I18n.t('lua disabled')} -->"
      end
    end

    protected
    def init_lua
      if @options[:disable_lua].nil?
        begin
          @options[:disable_lua] ||= DISABLE_LUA
          lua_max_lines = @options[:lua_max_lines] || 1000000
          lua_max_calls = @options[:lua_max_calls] || 20000

          unless @options[:disable_lua]
            @options[:luabridge] = Lua::State.new
            @options[:luabridge].eval(File.read(File.join(File.expand_path(File.dirname(__FILE__)), "lua", "luawrapper.lua")))
            @options[:luabridge].eval("wrap = make_wrapper(#{lua_max_lines},#{lua_max_calls})")
          end
        rescue
          @options[:disable_lua] = true
        end
      end
    end

    def lua_eval(code)
      @options[:luabridge]['chunkstr'] = code
      @options[:luabridge].eval("res, err = wrap(chunkstr, env, hook)")
      unless @options[:luabridge]['err'].nil?
        if @options[:luabridge]['err'] =~ /LOC_LIMIT/
          "<span class=\"error\">#{I18n.t("max lines of code")}</span>"
        elsif @options[:luabridge]['err'] =~ /RECURSION_LIMIT/
          "<span class=\"error\">#{I18n.t("recursion limit reached")}</span>"
        else
          "<span class=\"error\">#{@options[:luabridge]['err']}</span>"
        end
        nil
      else
        @options[:luabridge]['res']
      end
    end

  end
end
