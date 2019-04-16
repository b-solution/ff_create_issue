require 'redmine'

require_dependency 'issue_patch'

Redmine::Plugin.register :ff_create_issue do
  name 'RMClient create issue'
  author 'FORFORCE'
  description 'Redmine plugin to create issue with RMClient'
  version '0.0.1'
  url 'http://forforce.com/'
  author_url 'http://forforce.com/'

  # menu :application_menu, :new_issue, { :controller => 'issue', :action => 'new' }, :caption => 'Polls'
end

