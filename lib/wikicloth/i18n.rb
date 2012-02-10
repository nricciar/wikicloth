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

    def load_path
      @@load_paths ||= []
    end

    def load_path=(val)
      @@load_paths = val
    end

    def load_translations
      return if initialized?

      @@translations = {}
      load_path.each do |path|
        Dir[path].each do |file| 
          data = YAML::load(File.read(file))
          data.each do |key,value|
            @@translations[key.to_sym] ||= {}
            @@translations[key.to_sym].merge!(value)
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

    private
    def add_vars(string, options)
      options.each do |key,value|
        string.gsub!(/(%\{#{key}\})/, value.to_s)
      end
      string
    end
  end

end
