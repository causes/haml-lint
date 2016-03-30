require 'spec_helper'

describe HamlLint::Reporter::CheckstyleReporter do
  describe '#display_report' do
    let(:io) { StringIO.new }
    let(:output) { io.string }
    let(:logger) { HamlLint::Logger.new(io) }
    let(:report) { HamlLint::Report.new(lints, []) }
    let(:reporter) { described_class.new(logger) }

    subject { reporter.display_report(report) }

    shared_examples_for 'output format specification' do
      it 'matches the output specification' do
        subject
        output.should match /^<\?xml/
        output.should match /<checkstyle/
      end
    end

    context 'when there are no lints' do
      let(:lints) { [] }
      let(:files) { [] }

      it 'list of files is empty' do
        subject
        output.should_not match /<file/
      end

      it_behaves_like 'output format specification'
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { %w[502 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning, :error] }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(HamlLint::Linter::FinalNewline,
                             filename,
                             lines[index],
                             descriptions[index],
                             severities[index])
        end
      end

      it 'contains a list of files with offenses' do
        subject
        output.should match /<file name="some-filename.haml"/
        output.should match /<file name="other-filename.haml"/
      end

      it 'contains a list of errors within the files' do
        subject
        output.should match /<error line="724" severity="error"/
        output.should match /message="Description of lint 2"/
        output.should match %r{source="HamlLint::Linter::FinalNewline" \/>}
        output.should match /<error line="502" severity="warning"/
        output.should match /message="Description of lint 1"/
        output.should match %r{source="HamlLint::Linter::FinalNewline" \/>}
      end

      it_behaves_like 'output format specification'
    end
  end
end
