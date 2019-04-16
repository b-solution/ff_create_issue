# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'ff_new_issue', :to => 'ff_issue#new'
get 'ff_result', :to => 'ff_issue#result'
post 'ff_new_issue', :to => 'ff_issue#new'
post 'ff_create_issue', :to => 'ff_issue#create'
post 'ff_upload', :to => 'ff_issue#upload'
post 'ff_append_watchers', :to => 'ff_issue#append_watchers'
post 'ff_projects', :to => 'ff_issue#projects'
get 'ff_projects', :to => 'ff_issue#projects'
get 'ff_watchers/new', :to => 'ff_issue#new_watcher'
get 'ff_watchers_autocomplete', :to => 'ff_issue#new_watcher_autocomplete'
delete 'ff_delete_attachment', :to => 'ff_issue#delete_attachment'
