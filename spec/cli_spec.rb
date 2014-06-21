require 'spec_helper'
require 'haml_lint/cli'

describe HamlLint::CLI do
  before do
    # Silence console output
    @output = ''
    STDOUT.stub(:write) { |*args| @output.<<(*args) }
  end

  describe '#parse_arguments' do
    let(:files)   { ['file1.scss', 'file2.scss'] }
    let(:options) { [] }
    subject       { HamlLint::CLI.new(options + files) }

    def safe_parse
      subject.parse_arguments
    rescue SystemExit
      # Keep running tests
    end

    context 'when the excluded files flag is set' do
      let(:options) { %w[-e file1.haml,file3.haml] }

      it 'sets the :excluded_files option' do
        safe_parse
        subject.options[:excluded_files].should =~ ['file1.haml', 'file3.haml']
      end
    end

    context 'when the include linters flag is set' do
      let(:options) { %w[-i SomeLinterName] }

      it 'sets the :included_linters option' do
        safe_parse
        subject.options[:included_linters].should == ['SomeLinterName']
      end
    end

    context 'when the exclude linters flag is set' do
      let(:options) { %w[-x SomeLinterName] }

      it 'sets the :excluded_linters option' do
        safe_parse
        subject.options[:excluded_linters].should == ['SomeLinterName']
      end
    end

    context 'when the show linters flag is set' do
      let(:options) { ['--show-linters'] }

      it 'prints the linters' do
        subject.should_receive(:print_linters)
        safe_parse
      end
    end

    context 'when the help flag is set' do
      let(:options) { ['-h'] }

      it 'prints a help message' do
        subject.should_receive(:print_help)
        safe_parse
      end
    end

    context 'when the version flag is set' do
      let(:options) { ['-v'] }

      it 'prints the program version' do
        subject.should_receive(:print_version)
        safe_parse
      end
    end

    context 'when an invalid option is specified' do
      let(:options) { ['--non-existant-option'] }

      it 'prints a help message' do
        subject.should_receive(:print_help)
        safe_parse
      end
    end

    context 'when no files are specified' do
      let(:files) { [] }

      it 'sets :files option to the empty list' do
        safe_parse
        subject.options[:files].should be_empty
      end
    end

    context 'when files are specified' do
      it 'sets :files option to the list of files' do
        safe_parse
        subject.options[:files].should =~ files
      end
    end
  end

  describe '#run' do
    let(:files)   { ['file1.scss', 'file2.scss'] }
    let(:options) { {} }
    subject       { HamlLint::CLI.new }

    before do
      subject.stub(:options).and_return(options)
      HamlLint::Utils.stub(:extract_files_from).and_return(files)
    end

    def safe_run
      subject.run
    rescue SystemExit
      # Keep running tests
    end

    context 'when no files are specified' do
      let(:files) { [] }

      it 'exits with non-zero status' do
        subject.should_receive(:halt).with(-1)
        safe_run
      end
    end

    context 'when files are specified' do
      before { HamlLint::Runner.any_instance.stub(:run) }

      it 'passes the set of files to the runner' do
        HamlLint::Runner.any_instance.should_receive(:run).with(files)
        safe_run
      end

      it 'uses the default reporter' do
        HamlLint::Reporter::DefaultReporter.any_instance
          .should_receive(:report_lints)
        safe_run
      end
    end

    context 'when there are no lints' do
      before do
        HamlLint::Runner.any_instance.stub(:run)
        HamlLint::Runner.any_instance.stub(:lints).and_return([])
      end

      it 'exits cleanly' do
        subject.should_not_receive(:halt)
        safe_run
      end

      it 'outputs nothing' do
        safe_run
        @output.should be_empty
      end
    end
  end

  describe '#report_lints' do
    context 'when the same file has 2 errors but only one line' do
      let(:filenames)    { ['some-filename.haml', 'some-filename.haml'] }
      let(:lines)        { [502, nil] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(filename, lines[index], descriptions[index],
                             severities[index])
        end
      end

      subject { HamlLint::CLI.new }

      it 'sorts nil line without blowing up' do
        subject.send(:report_lints, lints).should_not raise_exception
      end
    end
  end
end
