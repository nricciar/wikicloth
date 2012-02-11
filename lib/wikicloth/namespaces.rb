module WikiCloth

  class WikiNamespaces
  class << self

    NAMESPACE_TYPES = [:file,:category,:template,:special,:language,:help,:talk]

    def language_namespace_names
      I18n.available_locales.collect { |l| l.to_s.gsub(/[_]+/,'-') }
    end

    def language_name(ns, locale=nil)
      return nil unless language_namespace_names.include?(ns)
      locale ||= I18n.locale
      I18n.with_locale(locale) do
        I18n.t("languages.#{ns}")
      end
    end

    def localise_ns(name, locale=nil)
      locale ||= I18n.locale
      ns_type = namespace_type(name)
      unless ns_type.nil? || ns_type == :language
        I18n.with_locale(locale) do
          I18n.t("namespaces.#{ns_type.to_s}").split(",").first
        end
      else
        name
      end
    end

    def namespace_type(name)
      return :language if language_namespace_names.include?(name)
      NAMESPACE_TYPES.each { |ns| return ns if send("#{ns}_namespace_names").include?(name.downcase) }
      nil
    end

    def method_missing(method, *args)
      if method.to_s =~ /^([a-z]+)_namespace_names$/
        @@ns_cache ||= {}
        @@ns_cache[$1] ||= get_namespace_names_for($1) 
      elsif method.to_s =~ /^([a-z]+)_namespace\?$/
        namespace_type(args.first) == $1.to_sym ? true : false
      else
        super(method, *args)
      end
    end

    def get_namespace_names_for(name)
      ret = []
      I18n.available_locales.each do |locale|
        I18n.with_locale(locale) do
          I18n.t("namespaces.#{name}").split(",").each { |ns| ret << ns.downcase unless ret.include?(ns.downcase) }
        end
      end
      ret
    end

  end
  end

end
