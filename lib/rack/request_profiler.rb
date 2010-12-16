require 'ruby-prof'

module Rack
  class RequestProfiler
    def initialize(app, options = {})
      @app = app
      @printer = options[:printer] || ::RubyProf::GraphHtmlPrinter
      @mode = options[:mode] || ::RubyProf::PROCESS_TIME
      @eliminations = options[:eliminations]

      @path = options[:path]
      @path ||= Rails.root + 'tmp/performance' if defined?(Rails)
      @path ||= ::File.join(ENV["TMPDIR"] + 'performance')
      @path = Pathname(@path)
    end

    def call(env)
      request = Rack::Request.new(env)
      profile_request = request.params.delete("profile_request") == "true"

      if profile_request
        ::RubyProf.measure_mode = @mode
        ::RubyProf.start
      end
      status, headers, body = @app.call(env)

      if profile_request
        result = ::RubyProf.stop
        write_result(result, request)
      end
      
      [status, headers, body]
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
      printer = @printer.new(result)
      Dir.mkdir(@path) unless ::File.exists?(@path)
      url = request.fullpath.gsub(/[?\/]/, '-')
      filename = "#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}-#{url}.#{format(printer)}"
      ::File.open(@path + filename, 'w+') do |f|
        # HACK to keep this from crashing under patched 1.9.2
        GC.disable
        printer.print(f)
        GC.enable
      end
    end
  end
end
