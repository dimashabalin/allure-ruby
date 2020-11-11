require 'net/https'
require 'json'
require_relative 'jira_config'

module JIRAHelper
  def jira_issue_fields(issue, *fields)
    json_response = parse_response jira_issue_request(issue)
    issue_fields = {}

    fields.each do |field|
      issue_fields[field] = dig_issue_field(json_response, field)
    end
    issue_fields
  end

  def jira_issues_search(project, *fields)
    json_response = parse_response jira_search_request(project, fields: fields)
    issues = {}

    json_response.dig('issues')&.each do |issue|
      issue_fields = {}
      fields.each do |field|
        issue_fields[field] = dig_issue_field(issue, field)
      end
      issues[issue['key']] = issue_fields
    end
    issues
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

  private

  def jira_issue_request(issue)
    uri = URI(JIRA_ISSUE_URL + issue.to_s)
    jira_request(uri)
  end

  def jira_search_request(
      project,
      issue_type: 'Test',
      automated: ['Yes', 'Pending', 'To update'],
      fields: %w[priority status automated],
      max_results: 500
  )
    # Wrap automated field values. Should be quoted for jql if includes spaces
    automated_values = automated.map { |value| value.include?(' ') ? "'#{value}'" : value }.join(',')
    jql = "project=#{project} and issuetype=#{issue_type} and Automated in (#{automated_values})".sub(' ', '+')
    s_fields = (['key'] + fields.map { |field| JIRA_ISSUE_FIELDS[field] }).join(',')
    uri = URI(JIRA_ISSUE_URL.sub('issue', 'search') + "?jql=#{jql}" + "&fields=#{s_fields}" + "&maxResults=#{max_results}")
    jira_request(uri)
  end

  def jira_request(uri)
    Net::HTTP.start(
      uri.host, uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
      open_timeout: 15,
      read_timeout: 30
    ) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth JIRA_ACCOUNT_NAME, JIRA_ACCOUNT_PASSWORD
      http.request request
    end
  rescue => e
    puts "smth wrong with connection to jira:\n#{e}\n#{e.backtrace.join("\n")}"
  end

  def dig_issue_field(issue_object, field)
    issue_object.dig('fields', JIRA_ISSUE_FIELDS[field], 'name') ||
        issue_object.dig('fields', JIRA_ISSUE_FIELDS[field], 'value')
  end

  def parse_response(response)
    JSON.parse(response.body)
  rescue => e
    puts "non-json body in jira response. code: #{response.code}"
    {}
  end
end
