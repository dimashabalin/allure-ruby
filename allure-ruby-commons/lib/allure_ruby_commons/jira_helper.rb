require 'net/https'
require 'json'
require_relative 'jira_config'

module JIRAHelper
  def issue(issue, field = JIRA_ISSUE_FIELDS['status'])
    uri = URI(JIRA_ISSUE_URL + issue.to_s)
    issue_status = ''
    jira_response = nil
    begin
      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
        open_timeout: 15,
        read_timeout: 30
      ) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth JIRA_ACCOUNT_NAME, JIRA_ACCOUNT_PASSWORD

        jira_response = http.request request

        json_resp = JSON.parse(jira_response.body)
        issue_status = json_resp['fields'][field]['name']
      end
    rescue
      case jira_response
      when Net::HTTPSuccess
        puts "jira response body was changed: #{jira_response.body}"
      else
        puts 'smth wrong with connection to jira'
      end
    end
    issue_status
  end

  def pending_msg(issue_id, issue_status)
    "Bug '#{issue_id}' is in status '#{issue_status}'."
  end

  def delete_bug_msg(issue_id, issue_status)
    "Bug '#{issue_id}' is in status '#{issue_status}'. Need to delete BugId from test."
  end

  def strange_behavior_msg(issue_id, issue_status, test_status)
    "Bug '#{issue_id}' is in status '#{issue_status}', but test is '#{test_status}'. Need to check bug status in jira"
  end

  def priority_msg(test_id, jira_priority, test_priority)
    "There is test '#{test_id}' with priority '#{test_priority}', but in jira priority is '#{jira_priority}'. Need to check."
  end

  def to_update_mgs(test_id)
    "Test '#{test_id}' is in '#{JIRA_ISSUE_TO_UPDATE}' automated status. Need to check and change status."
  end
end
