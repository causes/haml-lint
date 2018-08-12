RSpec::Matchers.define :report_lint do |options|
  options ||= {}
  count = options[:count]
  expected_line = options[:line]
  expected_message = options[:message]
  expected_severity = options[:severity]

  match do |linter|
    has_lints?(linter, expected_line, count, expected_message, expected_severity)
  end

  failure_message do |linter|
    'expected that a lint would be reported' +
      extended_expectations(expected_line, expected_message, expected_severity) +
      case linter.lints.count
      when 0
        ''
      when 1
        messages = [', but']
        messages << "reported message '#{linter.lints.first.message}'" if expected_message
        if expected_line
          messages << 'was' unless expected_message
          messages << "on line #{linter.lints.first.line}"
          messages << "with severity '#{linter.lints.first.severity}'" if expected_severity
        end
        messages.join ' '
      else
        lines = lint_lines(linter)
        ", but lints were reported on lines #{lines[0...-1].join(', ')} and #{lines.last}"
      end
  end

  failure_message_when_negated do |linter|
    message = ['expected that a lint would not be reported, but reported ']

    message <<
      case linter.lints.count
      when 1 then "1 lint:\n"
      else "#{linter.lints.count} lints:\n"
      end

    linter.lints.each do |lint|
      message << "  - Line #{lint.line}: #{lint.message}"
    end

    message.join
  end

  description do
    'report a lint' + extended_expectations(expected_line, expected_message, expected_severity)
  end

  def extended_expectations(expected_line, expected_message, expected_severity)
    (expected_line ? " on line #{expected_line}" : '') +
      (expected_message ? " with message '#{expected_message}'" : '') +
      (expected_severity ? " with severity '#{expected_severity}'" : '')
  end

  def has_lints?(linter, expected_line, count, expected_message, expected_severity)
    if expected_line
      has_expected_line_lints?(linter, expected_line, count, expected_message, expected_severity)
    elsif count
      linter.lints.count == count
    elsif expected_message
      lint_messages_match?(linter, expected_message)
    else
      linter.lints.any?
    end
  end

  def has_expected_line_lints?(linter, expected_line, count, expected_message, expected_severity)
    if count
      multiple_lints_match_line?(linter, expected_line, count)
    elsif expected_message
      lint_on_line_matches_message?(linter, expected_line, expected_message)
    elsif expected_severity
      lint_on_line_matches_severity?(linter, expected_line, expected_severity)
    else
      lint_lines(linter).include?(expected_line)
    end
  end

  def multiple_lints_match_line?(linter, expected_line, count)
    linter.lints.count == count &&
      lint_lines(linter).all? { |line| line == expected_line }
  end

  def lint_on_line_matches_message?(linter, expected_line, expected_message)
    linter.lints.any? { |lint| lint.line == expected_line && lint.message == expected_message }
  end

  def lint_on_line_matches_severity?(linter, expected_line, expected_severity)
    linter.lints.any? { |lint| lint.line == expected_line && lint.severity == expected_severity }
  end

  def lint_messages_match?(linter, expected_message)
    lint_messages(linter).all? { |message| message == expected_message }
  end

  def lint_lines(linter)
    linter.lints.map(&:line)
  end

  def lint_messages(linter)
    linter.lints.map(&:message)
  end
end
