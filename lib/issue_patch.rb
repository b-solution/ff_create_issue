if Redmine::VERSION::MAJOR < 3
  require_dependency 'issue'

  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def default_status
        IssueStatus.default
      end
    end
  end

  Issue.send(:include, IssuePatch)
end