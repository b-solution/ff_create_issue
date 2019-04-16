class FfIssueController < ApplicationController
  protect_from_forgery with: :null_session #, exception: false
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_if_login_required

  unloadable

  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :sort
  include SortHelper
  helper :timelog
  require File.dirname(__FILE__) + '/../helpers/ff_issues_helper'
  require File.dirname(__FILE__) + '/../helpers/ff_watchers_helper'
  helper :ff_issues
  helper :ff_watchers

  before_filter :set_lang
  before_filter :find_user, :except => [:append_watchers]
  before_filter :find_project, :only => [:new, :new_watcher, :new_watcher_autocomplete, :create]
  before_filter :build_new_issue_from_params, :only => [:new, :create]

  def new_watcher
    @users = users_for_new_watcher
  end

  def append_watchers
    if params[:watcher].is_a?(Hash)
      user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
      @users = User.active.where(:id => user_ids).to_a
    end
    if @users.blank?
      render :nothing => true
    end
  end

  def new_watcher_autocomplete
    @users = users_for_new_watcher
    render :layout => false
  end

  def delete_attachment
    begin
      @attachment = Attachment.find(params[:id])
      # Show 404 if the filename in the url is wrong
      raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
      @project = @attachment.project
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    unless @attachment.deletable?(@user)
      raise ActionController::RoutingError.new('Not Found')
    end
    if @attachment.container.respond_to?(:init_journal)
      @attachment.container.init_journal(@user)
    end
    if @attachment.container
      # Make sure association callbacks are called
      @attachment.container.attachments.delete(@attachment)
    else
      @attachment.destroy
    end

    respond_to do |format|
      format.html { redirect_to_referer_or project_path(@project) }
      format.js
    end
  end

  def result
    @issue = Issue.find params[:issue_id]
    render :layout => false
  end

  def new
    # @issue = Issue.new
    # @issue.project = Project.first
    # @priorities = IssuePriority.active
    @users = users_for_new_watcher

    respond_to do |format|
      format.html { render :layout => false }
      format.js
    end
    # render :partial => 'new'
  end

  def upload
    # Make sure that API users get used to set this content type
    # as it won't trigger Rails' automatic parsing of the request body for parameters
    unless request.content_type == 'application/octet-stream'
      render :nothing => true, :status => 406
      return
    end

    @attachment = Attachment.new(:file => request.raw_post)
    @attachment.author = @user
    @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
    @attachment.content_type = params[:content_type].presence
    saved = @attachment.save

    respond_to do |format|
      format.js
      # format.api {
      #   if saved
      #     render :action => 'upload', :status => :created
      #   else
      #     render_validation_errors(@attachment)
      #   end
      # }
    end
  end

  def create
    unless @user.allowed_to?(:add_issues, @issue.project, :global => true)
      raise ::Unauthorized
    end

    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    if @issue.save
      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@issue)
          # message = l(:notice_issue_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
          render :json => {status: 'ok', issue_id: @issue.id}
          # redirect_to :controller => 'issue', :action => 'new', :api_key => params[:api_key], :project_id => params[:project_id]
        }
      end
      return
    else
      respond_to do |format|
        format.html {
          if @issue.project.nil?
            render_error :status => 422
          else
            render :json => {status: 'error', error_message: error_messages_for(@issue)}
          end
        }
      end
    end
  end

  def projects
    @projects = Project.allowed_to @user, :add_issues
    
    unless session[:ff_api_key].present?
      session[:ff_api_key] = params[:api_key]
    end
    render :layout => false
  end

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = @user.allowed_to?({:controller => 'issues', :action => 'new'}, @project, :global => true)
    unless allowed
      raise ActionController::RoutingError.new('Not Found')
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError.new('Not Found')
  end

  def find_user

    if params[:api_key].present?
      key = params[:api_key]
    elsif session[:ff_api_key].present?
      key = session[:ff_api_key]
    end
    if key.present?
      @user = User.find_by_api_key(key)
    end
    if !key.present? || !@user.present?
      raise ActionController::RoutingError.new('Not Found')
    end
    User.current = @user
  end

  def build_new_issue_from_params
    @issue = Issue.new
    if params[:copy_from]
      begin
        @issue.init_journal(@user)
        @copy_from = Issue.visible.find(params[:copy_from])
        unless @user.allowed_to?(:copy_issues, @copy_from.project)
          raise ::Unauthorized
        end
        @link_copy = link_copy?(params[:link_copy]) || request.get?
        @copy_attachments = params[:copy_attachments].present? || request.get?
        @copy_subtasks = params[:copy_subtasks].present? || request.get?
        @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks, :link => @link_copy)
      rescue ActiveRecord::RecordNotFound
        render_404
        return
      end
    end
    @issue.project = @project
    if request.get?
      @issue.project ||= @issue.allowed_target_projects.first
    end
    @issue.author ||= @user
    @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?

    if params[:issue].present? && attrs = params[:issue].deep_dup
      if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
        attrs.delete(:status_id)
      end
      @issue.safe_attributes = attrs
    end
    if @issue.project
      @issue.tracker ||= @issue.project.trackers.first
      if @issue.tracker.nil?
        render_error l(:error_no_tracker_in_project)
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    end

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(@user, @issue.new_record?)
  end

  def set_lang
    I18n.locale = :en
  end

  def error_messages_for(*objects)
    html = ""
    objects = objects.map {|o| o.is_a?(String) ? instance_variable_get("@#{o}") : o}.compact
    errors = objects.map {|o| o.errors.full_messages}.flatten
    if errors.any?
      html << "<div id='errorExplanation'><ul>\n"
      errors.each do |error|
        html << "<li>#{error}</li>\n"
      end
      html << "</ul></div>\n"
    end
    html.html_safe
  end

  def users_for_new_watcher
    scope = nil
    if params[:q].blank? && @project.present?
      users = @project.users.limit 100
    else
      users = User.active.limit(100).sorted.like(params[:q]).to_a
    end
    return users
    users = scope.active.visible.sorted.like(params[:q]).to_a
    if @watched
      users -= @watched.watcher_users
    end
    users
  end
end