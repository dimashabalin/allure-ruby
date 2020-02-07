# Allure ruby

So this is generally fork of [allure-ruby](https://rubydoc.info/github/allure-framework/allure-ruby/master) with some dirty hacks to add features into allure-cucumber:
1. handle of cucumber `@testType:screenshotDiff` tag to support [screen-diff-plugin](https://github.com/allure-framework/allure2/tree/master/plugins/screen-diff-plugin)
2. check jira issue status to skip tests failures due to known issues
3. cucumber_failure.log generation without known jira issues to optimize rerunning
