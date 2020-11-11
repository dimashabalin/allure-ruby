require "cucumber/core"

require_relative "models/cucumber_model"
require_relative "models/tag_parser"

module AllureCucumber
  # Tests status logger formatter class. Logging tests "automated" status
  class JiraStatusLogger
    include TagParser

    def initialize(config)
      @out_file = config.out_stream.is_a?(String) ? config.out_stream : 'jira_status.log'
      config.on_event(:test_case_finished, &method(:on_test_case_finished))
      config.on_event(:test_run_finished, &method(:on_test_run_finished))
    end

    attr_writer :tests_status

    # Handle test case finished event
    # @param [Cucumber::Core::Events::TestCaseFinished] event
    # @return [void]
    def on_test_case_finished(event)
      # check Automated status for testcase (e.g. @TEST-)
      tags = event.test_case.tags.map(&:name)
      test_ids = tms_links(tags).map(&:name)
      priority = severity(tags).value
      bugs = issue_links(tags).map(&:name).join(',')

      test_ids.each do |test_id|
        unless tests_status[test_id]
          jira_fields = Allure::ResultUtils.jira_issue_fields(test_id, 'status', 'automated', 'priority')
          tests_status[test_id] = {
            automation_priority: priority,
            automation_status: bugs.empty? ? 'Running' : bugs
          }.merge(jira_fields)
        end
      end
    end

    # Handle test run finished event
    # @param [Cucumber::Core::Events::TestRunFinished] event
    # @return [void]
    def on_test_run_finished(event)
      print_tests_status
    end

    private

    def tests_status
      @tests_status ||= {}
    end

    def print_tests_status
      File.open(@out_file, 'a') { |f| f.write(fold_csv.join("\n") + "\n") }
    end

    def fold_csv
      tests_status.map do |test, status|
        test + ';' + status.values.join(';')
      end
    end
  end
end
