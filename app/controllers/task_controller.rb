=begin
RailsCollab
-----------

=end

class TaskController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete_list, :delete_task, :open_task, :complete_task ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }
  
  before_filter :login_required
  before_filter :process_session
  after_filter  :user_track, :only => [:index, :view_list]
  
  def index
    @open_task_lists = @active_project.open_task_lists
    @completed_task_lists = @active_project.completed_task_lists
    @content_for_sidebar = 'index_sidebar'
  end
  
  # Task lists
  def view_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task list"
      redirect_back_or_default :controller => 'task', :action => 'index'
      return
    end
    
    if not @task_list.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task', :action => 'index'
      return
    end
    
    @open_task_lists = @active_project.open_task_lists
    @completed_task_lists = @active_project.completed_task_lists
    @content_for_sidebar = 'index_sidebar'
  end
  
  def add_list    
    if not ProjectTaskList.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task_list = ProjectTaskList.new
    
    case request.method
      when :get
        begin
          @task_list.project_milestone = ProjectMilestone.find(params[:milestone_id])
          @task_list.is_private = @task_list.project_milestone.is_private
        rescue ActiveRecord::RecordNotFound
          @task_list.milestone_id = 0
          @task_list.is_private = false
        end
      when :post
        task_attribs = params[:task_list]
        
        @task_list.update_attributes(task_attribs)
        @task_list.created_by = @logged_user
        @task_list.project = @active_project
        
        @task_list.is_private = task_attribs[:is_private] if @logged_user.member_of_owner?
        
        if @task_list.save
          ApplicationLog::new_log(@task_list, @logged_user, :add, @task_list.is_private)
          
          @task_list.tags = task_attribs[:tags]
        
          flash[:flash_success] = "Successfully added task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def edit_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task_list.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    case request.method
      when :post
        task_attribs = params[:task_list]
        
        @task_list.update_attributes(task_attribs)
        
        @task_list.updated_by = @logged_user
        @task_list.tags = task_attribs[:tags]
        
        @task_list.is_private = task_attribs[:is_private] if @logged_user.member_of_owner?
        
        if @task_list.save
          ApplicationLog::new_log(@task_list, @logged_user, :edit, @task_list.is_private)
          flash[:flash_success] = "Successfully modified task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def delete_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task_list.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    ApplicationLog::new_log(@task_list, @logged_user, :delete, @task_list.is_private)
    @task_list.destroy
    
    flash[:flash_success] = "Successfully deleted task"
    redirect_back_or_default :controller => 'milestone'
  end
  
  def reorder_tasks
  end
  
  # Tasks
  def add_task
    begin
      @task_list = ProjectTaskList.find(params[:task_list_id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task list"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not ProjectTask.can_be_created_by(@logged_user, @task_list.project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task = ProjectTask.new
    
    case request.method
      when :post
        task_attribs = params[:task]
        
        @task.update_attributes(task_attribs)
        @task.created_by = @logged_user
        @task.task_list = @task_list
        
        if @task.save
          ApplicationLog::new_log(@task, @logged_user, :add, @task_list.is_private, @active_project)
          flash[:flash_success] = "Successfully added task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def edit_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    case request.method
      when :post
        task_attribs = params[:task]
        
        @task.update_attributes(task_attribs)
        @task.updated_by = @logged_user
        
        if @task.save
          ApplicationLog::new_log(@task, @logged_user, :edit, @task.task_list.is_private, @active_project)
          flash[:flash_success] = "Successfully modified task"
          redirect_back_or_default :controller => 'task'
        end
    end 
  end
  
  def delete_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    ApplicationLog::new_log(@task, @logged_user, :delete, @task.task_list.is_private, @active_project)
    @task.destroy
    
    flash[:flash_success] = "Successfully deleted task"
    redirect_back_or_default :controller => 'milestone'
  end
  
  def complete_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.completed_by.nil?
      flash[:flash_error] = "Task already completed"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task.completed_on = Time.now.utc
    @task.completed_by = @logged_user
    
    if @task.valid?
      ApplicationLog::new_log(@task, @logged_user, :close, @task.task_list.is_private, @active_project)
    end
    
    if not @task.save
      flash[:flash_error] = "Error saving"
    else
      # add a log entry for the task list
      if @task.task_list.finished_all_tasks?
        ApplicationLog::new_log(@task.task_list, @task.completed_by, :close, false)
      end
    end
    
    redirect_back_or_default :controller => 'task'
  end
  
  def open_task
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid task"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    if @task.completed_by.nil?
      flash[:flash_error] = "Task already open"
      redirect_back_or_default :controller => 'task'
      return
    end
    
    @task.completed_on = 0
    @task.completed_by = nil
    
    if not @task.save
      flash[:flash_error] = "Error saving"
    else
      if not @task.task_list.finished_all_tasks?
        ApplicationLog::new_log(@task.task_list, @logged_user, :open, @task.task_list.is_private)
      end
      ApplicationLog::new_log(@task, @logged_user, :open, @task.task_list.is_private, @active_project)
    end
    
    redirect_back_or_default :controller => 'task'
  end
end