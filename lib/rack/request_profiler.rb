require 'ruby-prof'

module Rack
  class RequestProfiler
    def initialize(app, options = {})
      @app = app
      @printer = options[:printer] || ::RubyProf::GraphHtmlPrinter
      @exclusions = options[:exclude]

      @path = options[:path]
      @path ||= Rails.root + 'tmp/performance' if defined?(Rails)
      @path ||= ::File.join(ENV["TMPDIR"] + 'performance')
      @path = Pathname(@path)
    end

    def call(env)
      request = Rack::Request.new(env)
      mode = profile_mode(request)
      
      if mode
        ::RubyProf.measure_mode = mode
        ::RubyProf.start
      end
      status, headers, body = @app.call(env)

      if mode
        result = ::RubyProf.stop
        write_result(result, request)
      end
      
      [status, headers, body]
    end

    def profile_mode(request)
      mode_string = request.params["profile_request"]
      if mode_string
        if mode_string.downcase == "true"
          ::RubyProf::PROCESS_TIME
        else
          ::RubyProf.const_get(mode_string.upcase)
        end
      end
    end

    def format(printer)
      case printer
      when ::RubyProf::FlatPrinter
        'txt'
      when ::RubyProf::FlatPrinterWithLineNumbers
        'txt'
      when ::RubyProf::GraphPrinter
        'txt'
      when ::RubyProf::GraphHtmlPrinter
        'html'
      when ::RubyProf::DotPrinter
        'dot'
      when ::RubyProf::CallTreePrinter
        "out.#{Process.pid}"
      when ::RubyProf::CallStackPrinter
        'html'
      else
        'txt'
      end
    end

    def write_result(result, request)
      result.eliminate_methods!(@exclusions) if @exclusions
      printer = @printer.new(result)
      Dir.mkdir(@path) unless ::File.exists?(@path)
      url = request.fullpath.gsub(/[?\/]/, '-')
      filename = "#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}-#{url}.#{format(printer)}"
      ::File.open(@path + filename, 'w+') do |f|
        printer.print(f)
      end
    end
  end
end
