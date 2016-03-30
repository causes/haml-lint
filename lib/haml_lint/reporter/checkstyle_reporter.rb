module HamlLint
  # Outputs report as an XML checkstyle document.
  class Reporter::CheckstyleReporter < Reporter
    def display_report(report)
      lints = report.lints
      files = lints.group_by(&:filename)

      xml = '<?xml version="1.0" encoding="utf-8"?>'

      xml << '<checkstyle version="5.7">'

      files.each do |filename, offenses|
        xml << "<file name=\"#{filename}\">"
        xml << render_offenses(offenses)
        xml << '</file>'
      end

      xml << '</checkstyle>'
      log.log xml
    end

    private

    def render_offenses(offenses)
      xml = ''
      offenses.each do |offense|
        xml << "<error line=\"#{offense.line}\" severity=\"#{offense.severity}\" "
        xml << "message=\"#{offense.message}\" source=\"#{offense.linter.name}\" />"
      end
      xml
    end
  end
end
