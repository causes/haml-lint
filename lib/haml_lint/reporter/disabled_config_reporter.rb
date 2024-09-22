# frozen_string_literal: true

require_relative 'progress_reporter'

module HamlLint
  # Outputs a YAML configuration file based on existing violations.
  class Reporter::DisabledConfigReporter < Reporter::ProgressReporter
    HEADING =
      ['# This configuration was generated by',
       '# `haml-lint --auto-gen-config`',
       "# on #{Time.now} using Haml-Lint version #{HamlLint::VERSION}.",
       '# The point is for the user to remove these configuration records',
       '# one by one as the lints are removed from the code base.',
       '# Note that changes in the inspected code, or installation of new',
       '# versions of Haml-Lint, may require this file to be generated again.']
      .join("\n")

    # Disables this reporter on the CLI since it doesn't output anything.
    #
    # @return [false]
    def self.available?
      false
    end

    # Create the reporter that will display the report and write the config.
    #
    # @param _log [HamlLint::Logger]
    def initialize(log, limit: 15)
      super(log)
      @linters_with_lints = Hash.new { |hash, key| hash[key] = [] }
      @linters_lint_count = Hash.new(0)
      @exclude_limit = limit
    end

    # A hash of linters with the files that have that type of lint.
    #
    # @return [Hash<String, Integer] a Hash with linter name keys and lint
    #   count values
    attr_reader :linters_lint_count

    # A hash of linters with the files that have that type of lint.
    #
    # @return [Hash<String, Array<String>>] a Hash with linter name keys and file
    #   name list values
    attr_reader :linters_with_lints

    # Number of offenses to allow before simply disabling the linter
    #
    # @return [Integer] file exclude limit
    attr_reader :exclude_limit

    # Prints the standard progress reporter output and writes the new config file.
    #
    # @param report [HamlLint::Report]
    # @return [void]
    def display_report(report)
      super

      File.write(ConfigurationLoader::AUTO_GENERATED_FILE, config_file_contents)
      log.log "Created #{ConfigurationLoader::AUTO_GENERATED_FILE}."
      log.log "Run `haml-lint --config #{ConfigurationLoader::AUTO_GENERATED_FILE}`" \
        ", or add `inherits_from: #{ConfigurationLoader::AUTO_GENERATED_FILE}` in a " \
        '.haml-lint.yml file.'
    end

    # Prints the standard progress report marks and tracks files with lint.
    #
    # @param file [String]
    # @param lints [Array<HamlLint::Lint>]
    # @return [void]
    def finished_file(file, lints)
      super

      if lints.any?
        lints.each do |lint|
          linters_with_lints[lint.linter.name] |= [lint.filename]
          linters_lint_count[lint.linter.name] += 1
        end
      end
    end

    private

    # The contents of the generated configuration file based on captured lint.
    #
    # @return [String] a Yaml-formatted configuration file's contents
    def config_file_contents
      output = []
      output << HEADING
      output << 'linters:' if linters_with_lints.any?
      linters_with_lints.each do |linter, files|
        output << generate_config_for_linter(linter, files)
      end
      output.join("\n\n")
    end

    # Constructs the configuration for excluding a linter in some files.
    #
    # @param linter [String] the name of the linter to exclude
    # @param files [Array<String>] the files in which the linter is excluded
    # @return [String] a Yaml-formatted configuration
    def generate_config_for_linter(linter, files)
      [].tap do |output|
        output << "  # Offense count: #{linters_lint_count[linter]}"
        output << "  #{linter}:"
        # disable the linter when there are many files with offenses.
        # exclude the affected files otherwise.
        if files.count > exclude_limit
          output << '    enabled: false'
        else
          output << '    exclude:'
          files.each do |filename|
            output << %{      - "#{filename}"}
          end
        end
      end.join("\n")
    end
  end
end
