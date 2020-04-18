require 'yaml'

USE_JIRA_ISSUE_STATUS = File.exist?('jira_config.yml')

jira_config = USE_JIRA_ISSUE_STATUS ? YAML.load_file('jira_config.yml') : {}
# jira_config.yml file should has following format
# ---
# JIRA_ISSUE_URL: https://<jira_url>/rest/api/latest/issue/
# JIRA_ACCOUNT_NAME: <username>
# JIRA_ACCOUNT_PASSWORD: <password>
# JIRA_ISSUE_TO_UPDATE: To update
# JIRA_ISSUE_FIELDS: 
#   status: status
#   priority: priority
#   automated: customfield_10100

# connection
JIRA_ISSUE_URL = jira_config['JIRA_ISSUE_URL']
JIRA_ACCOUNT_NAME = jira_config['JIRA_ACCOUNT_NAME']
JIRA_ACCOUNT_PASSWORD = jira_config['JIRA_ACCOUNT_PASSWORD']

# Automated field value 'to Update'
JIRA_ISSUE_TO_UPDATE = jira_config['JIRA_ISSUE_TO_UPDATE']

# issue fields
JIRA_ISSUE_FIELDS = jira_config['JIRA_ISSUE_FIELDS']
