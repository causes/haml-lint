describe HamlLint::Linter::MultilineScript do
  include_context 'linter'

  context 'when silent script is split with a Boolean operator' do
    let(:haml) { <<-HAML }
      - if condition ||
      - true
        Result
    HAML

    it { should report_lint line: 1 }
  end

  context 'when silent script is split with an equality operator' do
    let(:haml) { <<-HAML }
      - if condition ==
      - something
        Result
    HAML

    it { should report_lint line: 1 }
  end

  context 'when script is split with a binary operator' do
    let(:haml) { <<-HAML }
      = 1 +
      = 2
    HAML

    it { should report_lint line: 1 }
  end

  context 'when begin/rescue are used' do
    let(:haml) { <<-HAML }
      - begin
        = some_helper
      - rescue
        An error occurred
    HAML

    it { should_not report_lint }
  end
end
