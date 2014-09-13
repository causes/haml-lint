require 'spec_helper'

describe HamlLint::Parser do
  context 'when skip_frontmatter is true' do
    let(:parser) { HamlLint::Parser.new(haml, 'skip_frontmatter' => true) }

    let(:haml) { <<-HAML }
---
:key: value
---
%tag
  Some non-inline text
- 'some code'
    HAML

    it 'excludes the frontmatter' do
      expect(parser.contents).to eq(<<-CONTENT)
%tag
  Some non-inline text
- 'some code'
      CONTENT
    end

    context 'when haml has --- as content' do
      let(:haml) { <<-HAML }
---
:key: value
---
%tag
  Some non-inline text
- 'some code'
  ---
    HAML

      it 'is not greedy' do
        expect(parser.contents).to eq(<<-CONTENT)
%tag
  Some non-inline text
- 'some code'
  ---
      CONTENT
      end
    end
  end

  context 'when skip_frontmatter is false' do
    let(:parser) { HamlLint::Parser.new(haml, 'skip_frontmatter' => false) }
    let(:haml) { <<-HAML }
---
:key: value
---
%tag
  Some non-inline text
- 'some code'
    HAML

    it 'raises HAML error' do
      expect { parser }.to raise_error('Invalid filter name ":key: value".')
    end
  end
end
