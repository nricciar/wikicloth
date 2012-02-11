module I18n

  class << self

    def default_locale
      :en
    end

    def locale
      @@locale ||= default_locale
    end

    def locale=(val)
      @@locale = val
    end

    def t(*args)
      options  = args.last.is_a?(Hash) ? args.pop : {}
      key      = args.shift

      load_translations
      use_locale = @@translations[locale].nil? || @@translations[locale].empty? ? default_locale : locale

      if @@translations[use_locale].has_key?(key)
        add_vars(@@translations[use_locale][key], options)
      elsif use_locale != default_locale && @@translations[default_locale].has_key?(key)
        add_vars(@@translations[default_locale][key], options)
      else
        "translation missing: #{locale}, #{key}"
      end
    end

    def available_locales
      load_translations
      @@available_locales
    end

    def load_path
      @@load_paths ||= []
    end

    def load_path=(val)
      @@load_paths = val
    end

    def load_translations
      return if initialized?

      @@available_locales = []
      @@translations = {}
      load_path.each do |path|
        Dir[path].each do |file| 
          begin
            data = YAML::load(File.read(file))
            data.each do |key,value|
              @@available_locales << key.to_sym unless @@available_locales.include?(key.to_sym)
              @@translations[key.to_sym] ||= {}
              import_values(key.to_sym,value)
            end
          rescue ArgumentError => err
            puts "error in #{file}: #{err.message}"
          end
        end
      end

      initialized!
    end

    def initialized?
      @@initialized ||= false
    end

    def initialized!
      @@initialized = true
    end

    # Executes block with given I18n.locale set.
    def with_locale(tmp_locale = nil)
      if tmp_locale
        current_locale = self.locale
        self.locale    = tmp_locale
      end
      yield
    ensure
      self.locale = current_locale if tmp_locale
    end

    private
    def import_values(key,values,prefix=[])
      values.each do |k,value|
        if value.is_a?(Hash)
          import_values(key,value,prefix+[k])
        else
          @@translations[key.to_sym][(prefix+[k]).join(".")] = value
        end
      end
    end

    def add_vars(string, options)
      options.each do |key,value|
        string.gsub!(/(%\{#{key}\})/, value.to_s)
      end
      string
    end
  end

end
