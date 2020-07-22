# frozen_string_literal: true
require_relative 'jira_helper'
require "socket"

module Allure
  # Variouse helper methods
  module ResultUtils
    ISSUE_LINK_TYPE = "issue"
    TMS_LINK_TYPE = "tms"

    ALLURE_ID_LABEL_NAME = "AS_ID"
    SUITE_LABEL_NAME = "suite"
    PARENT_SUITE_LABEL_NAME = "parentSuite"
    SUB_SUITE_LABEL_NAME = "subSuite"
    EPIC_LABEL_NAME = "epic"
    FEATURE_LABEL_NAME = "feature"
    STORY_LABEL_NAME = "story"
    SEVERITY_LABEL_NAME = "severity"
    TAG_LABEL_NAME = "tag"
    TEST_TYPE_NAME = "testType"
    OWNER_LABEL_NAME = "owner"
    LEAD_LABEL_NAME = "lead"
    HOST_LABEL_NAME = "host"
    THREAD_LABEL_NAME = "thread"
    TEST_METHOD_LABEL_NAME = "testMethod"
    TEST_CLASS_LABEL_NAME = "testClass"
    PACKAGE_LABEL_NAME = "package"
    FRAMEWORK_LABEL_NAME = "framework"
    LANGUAGE_LABEL_NAME = "language"

    class << self
      include JIRAHelper
      # @param [Time] time
      # @return [Number]
      def timestamp(time = nil)
        ((time || Time.now).to_f * 1000).to_i
      end

      # Current thread label
      # @return [Allure::Label]
      def thread_label
        Label.new(THREAD_LABEL_NAME, Thread.current.object_id)
      end

      # Host label
      # @return [Allure::Label]
      def host_label
        Label.new(HOST_LABEL_NAME, Socket.gethostname)
      end

      # Language label
      # @return [Allure::Label]
      def language_label
        Label.new(LANGUAGE_LABEL_NAME, "ruby")
      end

      # Framework label
      # @param [String] value
      # @return [Allure::Label]
      def framework_label(value)
        Label.new(FRAMEWORK_LABEL_NAME, value)
      end

      # Feature label
      # @param [String] value
      # @return [Allure::Label]
      def feature_label(value)
        Label.new(FEATURE_LABEL_NAME, value)
      end

      # Package label
      # @param [String] value
      # @return [Allure::Label]
      def package_label(value)
        Label.new(PACKAGE_LABEL_NAME, value)
      end

      # Suite label
      # @param [String] value
      # @return [Allure::Label]
      def suite_label(value)
        Label.new(SUITE_LABEL_NAME, value)
      end

      # Parent suite label
      # @param [String] value
      # @return [Allure::Label]
      def parent_suite_label(value)
        Label.new(PARENT_SUITE_LABEL_NAME, value)
      end

      # Parent suite label
      # @param [String] value
      # @return [Allure::Label]
      def sub_suite_label(value)
        Label.new(SUB_SUITE_LABEL_NAME, value)
      end

      # Story label
      # @param [String] value
      # @return [Allure::Label]
      def story_label(value)
        Label.new(STORY_LABEL_NAME, value)
      end

      # Test case label
      # @param [String] value
      # @return [Allure::Label]
      def test_class_label(value)
        Label.new(TEST_CLASS_LABEL_NAME, value)
      end

      # Tag label
      # @param [String] value
      # @return [Allure::Label]
      def tag_label(value)
        Label.new(TAG_LABEL_NAME, value)
      end

      # Severity label
      # @param [String] value
      # @return [Allure::Label]
      def severity_label(value)
        Label.new(SEVERITY_LABEL_NAME, value)
      end

      # Test Type label
      # @param [String] value
      # @return [Allure::Label]
      def test_type_label(value)
        Label.new(TEST_TYPE_NAME, value)
      end

      # TMS link
      # @param [String] value
      # @return [Allure::Link]
      def tms_link(value)
        Link.new(TMS_LINK_TYPE, value, tms_url(value))
      end

      # Issue link
      # @param [String] value
      # @return [Allure::Link]
      def issue_link(value)
        Link.new(ISSUE_LINK_TYPE, value, issue_url(value))
      end

      # Get status based on exception type
      # @param [Exception] exception
      # @return [Symbol]
      def status(exception)
        exception.is_a?(RSpec::Expectations::ExpectationNotMetError) ? Status::FAILED : Status::BROKEN
      end

      def result_after_jira_check(test_case, run_status)
        issue_id = test_case.links.find { |link| link.type == 'issue' }&.name
        test_id = test_case.links.find { |link| link.type == 'tms' }&.name

        # compare run status with JIRA bug status to skip known or untag fixed
        if issue_id
          jira_status = issue(issue_id).to_s
          if jira_status == '' && run_status != Status::PASSED
            return Status::SKIPPED, "cannot get #{issue_id} status" + "\n"
          end
          if jira_status != 'Closed' && run_status == Status::FAILED
            return Status::SKIPPED, pending_msg(issue_id, jira_status) + "\n"
          end
          if jira_status == 'Closed' && run_status == Status::PASSED
            return Status::BROKEN, delete_bug_msg(issue_id, jira_status) + "\n"
          end
          if jira_status == 'Closed' && run_status != Status::PASSED
            return Status::FAILED, strange_behavior_msg(issue_id, jira_status, run_status) + "\n"
          end
          if jira_status != 'Closed' && run_status == Status::PASSED
            return Status::BROKEN, strange_behavior_msg(issue_id, jira_status, run_status) + "\n"
          end
        end

        # turned off due to one Jira issue might include TCs with different priorities
        # compare Jira status for specified TEST to find out if priority mismatch or
        # Automated status needs to update
        # if test_id
        #    jira_priority = issue(test_id, JIRA_ISSUE_FIELDS[:priority]).to_s.downcase
        #    priority = test_case.labels.severity.to_s.downcase == '' ? 'normal' : test_case.labels.severity.to_s.downcase == ''
        #    unless priority == jira_priority
        #      return Status::BROKEN, priority_msg(test_id, jira_priority, priority)
        #    end
        #   jira_automated_status = issue(test_id, JIRA_ISSUE_FIELDS[:automated]).to_s.downcase
        #   if jira_automated_status == JIRA_ISSUE_TO_UPDATE
        #     return Status::BROKEN, to_update_mgs(test_id)
        #   end
        # end
        [run_status, '']
      end

      # Get exception status detail
      # @param [Exception] exception
      # @return [Allure::StatusDetails]
      def status_details(exception)
        StatusDetails.new(message: exception&.message, trace: exception&.backtrace&.join("\n"))
      end

      # Allure attachment object
      # @param [String] name
      # @param [String] type
      # @return [Allure::Attachment]
      def prepare_attachment(name, type)
        extension = ContentType.to_extension(type) || return
        file_name = "#{UUID.generate}-attachment.#{extension}"
        Attachment.new(name: name, source: file_name, type: type)
      end

      private

      def tms_url(value)
        Allure.configuration.link_tms_pattern.sub("{}", value)
      end

      def issue_url(value)
        Allure.configuration.link_issue_pattern.sub("{}", value)
      end
    end
  end
end
