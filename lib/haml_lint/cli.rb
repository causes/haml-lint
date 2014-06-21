require 'optparse'

module HamlLint
  class CLI
    attr_accessor :options

    def initialize(args = [])
      @args = args
      @options = {}
    end

    def parse_arguments
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] [haml-files]"

        opts.separator ''
        opts.separator 'Common options:'

        opts.on('-e', '--exclude file,...', Array,
                'List of file names to exclude') do |files|
          options[:excluded_files] = files
        end

        opts.on('-i', '--include-linter linter,...', Array,
                'Specify which linters you want to run') do |linters|
          options[:included_linters] = linters
        end

        opts.on('-x', '--exclude-linter linter,...', Array,
                "Specify which linters you don't want to run") do |linters|
          options[:excluded_linters] = linters
        end

        opts.on_tail('--show-linters', 'Shows available linters') do
          print_linters
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          print_help opts.help
        end

        opts.on_tail('-v', '--version', 'Show version') do
          print_version opts.program_name, VERSION
        end
      end

      begin
        parser.parse!(@args)

        # Take the rest of the arguments as files/directories
        options[:files] = @args
      rescue OptionParser::InvalidOption => ex
        print_help parser.help, ex
      end
    end

    def run
      runner = Runner.new(options)
      runner.run(find_files)
      report_lints(runner.lints)
      halt 1 if runner.lints?
    rescue NoFilesError, NoSuchLinter, Errno::ENOENT => ex
      puts ex.message
      halt -1
    end

  private

    def find_files
      excluded_files = options.fetch(:excluded_files, [])

      Utils.extract_files_from(options[:files]).reject do |file|
        excluded_files.include?(file)
      end
    end

    def report_lints(lints)
      sorted_lints = lints.sort_by { |l| [l.filename, l.line || 0] }
      reporter = options.fetch(:reporter, Reporter::DefaultReporter).new(sorted_lints)
      output = reporter.report_lints
      print output if output
    end

    def print_linters
      puts 'Installed linters:'

      linter_names = LinterRegistry.linters.map do |linter|
        linter.name.split('::').last
      end

      linter_names.sort.each do |linter_name|
        puts " - #{linter_name}"
      end

      halt
    end

    def print_help(help_message, err = nil)
      puts err, '' if err
      puts help_message
      halt
    end

    def print_version(program_name, version)
      puts "#{program_name} #{version}"
      halt
    end

    # Used to to catch exit behaviour in tests
    def halt(exit_status = 0)
      exit exit_status
    end
  end
end
