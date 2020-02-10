# frozen_string_literal: true
require_relative "cucumber_model"

module AllureCucumber
  # Failure logger formatter class. Logging of all the failures avoing known issues to optimize rerun
  class FailuresLogger
    include AllureCucumberModel

    def initialize(config)
      @out_file = config.out_stream.is_a?(String) ? config.out_stream : 'cucumber_failures.log'
      config.on_event(:test_case_finished, &method(:on_test_case_finished))
      config.on_event(:test_run_finished, &method(:on_test_run_finished))
    end

    attr_writer :failures

    # Handle test case finished event
    # @param [Cucumber::Core::Events::TestCaseFinished] event
    # @return [void]
    def on_test_case_finished(event)
      # save only failed and not tagged with issue_pattern (e.g. @ISSUE-)
      if event.result.failed? && !event.test_case.tags.any? { |tag| tag.name.match?(reserved_patterns[:issue]) }
        add_failure_to_rerun(event.test_case)
      end
    end

    # Handle test run finished event
    # @param [Cucumber::Core::Events::TestRunFinished] event
    # @return [void]
    def on_test_run_finished(event)
      print_cucumber_failures
    end

    private
    
    def failures
      @failures ||= {}
    end

    def add_failure_to_rerun(test_case)
      failures[test_case.location.file] ||= []
      failures[test_case.location.file] << test_case.location.line
    end

    def print_cucumber_failures
      File.open(@out_file, 'a') { |f| f.write(file_failures.join("\n") + "\n") }
    end

    def file_failures
      failures.map { |file, lines| [file, lines].join(':') }
    end
  end
end