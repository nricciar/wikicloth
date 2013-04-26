begin
  require 'rubyluabridge'
  DISABLE_LUA = false
rescue LoadError
  DISABLE_LUA = true
end

module WikiCloth
  class LuaExtension < Extension

    # <lua var1="value" ...>lua code</lua>
    #
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
          WikiCloth.error_template err.message
        end
      else
        "<!-- #{I18n.t('lua disabled')} -->"
      end
    end

    # {{#luaexpr:lua expression}}
    #
    function '#luaexpr' do |params|
      init_lua
      unless @options[:disable_lua]
        begin
          lua_eval("print(#{params.first})").to_s
        rescue => err
          WikiCloth.error_template err.message
        end
      else
        "<!-- #{I18n.t('lua disabled')} -->"
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
          WikiCloth.error_template I18n.t("max lines of code")
        elsif @options[:luabridge]['err'] =~ /RECURSION_LIMIT/
          WikiCloth.error_template I18n.t("recursion limit reached")
        else
          WikiCloth.error_template @options[:luabridge]['err']
        end
        nil
      else
        @options[:luabridge]['res']
      end
    end

  end
end
