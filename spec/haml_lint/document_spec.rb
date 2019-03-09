describe HamlLint::Document do
  let(:config) { double }

  before do
    config.stub(:[]).with('skip_frontmatter').and_return(false)
  end

  describe '#initialize' do
    let(:source) { normalize_indent(<<-HAML) }
      %head
        %title My title
      %body
        %p My paragraph
    HAML

    let(:options) { { config: config } }

    subject { described_class.new(source, options) }

    it 'stores a tree representing the parsed document' do
      subject.tree.should be_a HamlLint::Tree::Node
    end

    it 'stores the source code' do
      subject.source == source
    end

    it 'stores the individual lines of source code' do
      subject.source_lines == source.split("\n")
    end

    context 'when file is explicitly specified' do
      let(:options) { super().merge(file: 'my_file.haml') }

      it 'sets the file name' do
        subject.file == 'my_file.haml'
      end
    end

    context 'when file is not specified' do
      it 'sets a dummy file name' do
        subject.file == HamlLint::Document::STRING_SOURCE
      end
    end

    context 'when skip_frontmatter is specified in config' do
      before do
        config.stub(:[]).with('skip_frontmatter').and_return(true)
      end

      context 'and the source contains frontmatter' do
        let(:source) { "---\nsome frontmatter\n---\n#{super()}" }

        it 'removes the frontmatter' do
          subject.source.should_not include '---'
          subject.source.should include '%head'
        end

        it 'reports line numbers as if frontmatter was not removed' do
          expect(subject.tree.children.first.line).to eq(4)
        end
      end

      context 'and the source does not contain frontmatter' do
        it 'leaves the source untouched' do
          subject.source == source
        end
      end
    end

    context 'when given an invalid HAML document' do
      let(:source) { normalize_indent(<<-HAML) }
        %body
          %div
              %p
      HAML

      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::ParseError
      end

      it 'includes the line number in the exception' do
        begin
          subject
        rescue HamlLint::Exceptions::ParseError => ex
          ex.line.should == 2
        end
      end
    end

    context 'when source is valid UTF-8 but was interpeted as US-ASCII' do
      let(:source) { '%p Test àéùö'.force_encoding('US-ASCII') }

      it 'interprets it as UTF-8' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when given a file with different line endings' do
      context 'that are just carriage returns' do
        let(:source) { "%div\r  %p\r    Hello, world" }

        it 'interprets the line endings as newlines, like Haml' do
          expect { subject }.to_not raise_error
        end
      end

      context 'that are Windows-style CRLF' do
        let(:source) { "%div\r\n  %p\r\n    Hello, world" }

        it 'interprets the line endings as newlines, like Haml' do
          expect { subject }.to_not raise_error
        end
      end
    end
  end
end
