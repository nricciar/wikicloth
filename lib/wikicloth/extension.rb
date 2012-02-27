module WikiCloth
  class Extension

    def initialize(options={})
      @options = options
    end

    class << self

      def html_elements
        @@html_elements ||= {}
      end

      def functions
        @@functions ||= {}
      end

      def element(*args,&block)
        options  = args.last.is_a?(Hash) ? args.pop : {}
        key      = args.shift

        html_elements[key] = { :klass => self, :block => block, :options => { 
          :skip_html => false, :run_globals => true }.merge(options) }
      end

      def skip_html?(elem)
        return true if !element_exists?(elem)
        html_elements[elem][:options][:skip_html]
      end

      def run_globals?(elem)
        return false if !element_exists?(elem)
        html_elements[elem][:options][:run_globals]
      end

      def element_exists?(elem)
        html_elements.has_key?(elem)
      end

      def function(name,&block)
        functions[name] = { :klass => self, :block => block }
      end

      def function_exists?(name)
        functions.has_key?(name)
      end

      protected
      def html_elements=(val)
        @@html_elements = val
      end

      def functions=(val)
        @@functions = val
      end

    end

  end
end
