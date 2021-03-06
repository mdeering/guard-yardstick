require 'guard/compat/plugin'
require 'yardstick'

module Guard
  # A guard plugin to run yardstick on every save
  class Yardstick < Plugin
    # A hash of options for configuring the plugin
    #
    # @api private
    # @return [Hash]
    attr_reader :options

    # Initializes guard-yardstick
    #
    # @api private
    # @return [Guard::Yardstick]
    def initialize(args = {})
      super

      @options = {
        all_on_start: true,
        # Taken from yardsitck:
        # https://github.com/dkubb/yardstick/blob/0aa394dd64baf5155775e6be5018d6c9844654b7/lib/yardstick/config.rb#L167
        path:         ['lib/**/*.rb']
      }.merge(args)
    end

    # When guard starts will run all files if :all_on_start is set
    #
    # @api private
    # @return [Void]
    def start
      run_all if options[:all_on_start]
    end

    # Will run all files through yardstick
    #
    # @api private
    # @return [Void]
    def run_all
      UI.info 'Inspecting Yarddoc in all files'
      inspect_with_yardstick(options[:path])
    end

    # Will run when files are added
    #
    # @api private
    # @return [Void]
    def run_on_additions(paths)
      run_partially(paths)
    end

    # Will run when files are changed
    #
    # @api private
    # @return [Void]
    def run_on_modifications(paths)
      run_partially(paths)
    end

    private

    # Runs yardstick on a partial set of paths passed in by guard
    #
    # @api private
    # @return [Void]
    def run_partially(paths)
      return if paths.empty?

      displayed_paths = paths.map { |path| smart_path(path) }
      UI.info "Inspecting Yarddocs: #{displayed_paths.join(' ')}"

      inspect_with_yardstick(paths)
    end

    # Runs yardstick and outputs results to STDOUT
    #
    # @api private
    # @return [Void]
    def inspect_with_yardstick(paths)
      config = ::Yardstick::Config.coerce(path: paths)
      measurements = ::Yardstick.measure(config)
      measurements.puts
    rescue => error
      UI.error 'The following exception occurred while running ' \
               "guard-yardstick: #{error.backtrace.first} " \
               "#{error.message} (#{error.class.name})"
    end

    # Returns a path with pwd removed if needed
    #
    # @api private
    # @return [String]
    def smart_path(path)
      if path.start_with?(Dir.pwd)
        Pathname.new(path).relative_path_from(Pathname.getwd).to_s
      else
        path
      end
    end
  end
end
