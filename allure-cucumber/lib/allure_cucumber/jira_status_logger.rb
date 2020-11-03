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

    attr_writer :jira_test_status

    # Handle test case finished event
    # @param [Cucumber::Core::Events::TestCaseFinished] event
    # @return [void]
    def on_test_case_finished(event)
      # check Automated status for testcase (e.g. @TEST-)
      test_id = event.test_case.links.find { |link| link.type == 'tms' }&.name
      if test_id && !tests_status[test_id]
        add_test_status(test_id)
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

    def add_test_status(test_id)
      tests_status[test_id] = jira_issue_fields(
                                JIRA_ISSUE_FIELDS['status'],
                                JIRA_ISSUE_FIELDS['automated'],
                                JIRA_ISSUE_FIELDS['priority'],
                              )
    end

    def print_tests_status
      File.open(@out_file, 'a') { |f| f.write(fold_csv.join("\n") + "\n") }
    end

    def fold_csv
      tests_status.map do |test, status|
        test + ',' +
         status[JIRA_ISSUE_FIELDS['status']] + ',' +
          status[JIRA_ISSUE_FIELDS['automated']] + ',' +
           status[JIRA_ISSUE_FIELDS['priority']]
      end
    end
  end
end
