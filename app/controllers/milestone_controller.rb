=begin
RailsCollab
-----------

=end

class MilestoneController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete, :complete, :open ],
  		 :add_flash => { :flash_error => "Invalid request" },
         :redirect_to => { :controller => 'project' }
    
  before_filter :login_required
  before_filter :process_session
  before_filter :obtain_milestone, :except => [:index, :add]
  after_filter  :user_track, :only => [:index, :view]
  
  def index
    @late_milestones = @active_project.late_milestones
    @today_milestones = @active_project.today_milestones
    @upcomming_milestones = @active_project.upcomming_milestones
    @completed_milestones = @active_project.completed_milestones
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  def view
    if not @milestone.can_be_seen_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
  end
  
  def add
    @milestone = ProjectMilestone.new
    
    if not ProjectMilestone.can_be_created_by(@logged_user, @active_project)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
        
    case request.method
      when :post
        milestone_attribs = params[:milestone]
        
        @milestone.update_attributes(milestone_attribs)
        
        @milestone.created_by = @logged_user
        @milestone.project = @active_project
        
        @milestone.is_private = milestone_attribs[:is_private] if @logged_user.member_of_owner?
        
        if @milestone.save
          ApplicationLog::new_log(@milestone, @logged_user, :add, @milestone.is_private)
          
          @milestone.tags = milestone_attribs[:tags]
          
          flash[:flash_success] = "Successfully updated milestone"
          redirect_back_or_default :controller => 'milestone'
        end
    end 
  end
  
  def edit
    if not @milestone.can_be_edited_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    case request.method
      when :post
        milestone_attribs = params[:milestone]
        
        @milestone.update_attributes(milestone_attribs)
        @milestone.updated_by = @logged_user
        @milestone.tags = milestone_attribs[:tags]
        
        @milestone.is_private = milestone_attribs[:is_private] if @logged_user.member_of_owner?
        
        if @milestone.save
          ApplicationLog::new_log(@milestone, @logged_user, :edit, @milestone.is_private)
          flash[:flash_success] = "Successfully updated milestone"
          redirect_back_or_default :controller => 'milestone'
        end
    end     
  end
  
  def delete
    if not @milestone.can_be_deleted_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    ApplicationLog::new_log(@milestone, @logged_user, :delete, @milestone.is_private)
    @milestone.destroy
    
    flash[:flash_success] = "Successfully deleted milestone"
    redirect_back_or_default :controller => 'milestone'
  end
  
  def complete
    if not @milestone.status_can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
   
    if not @milestone.completed_by.nil?
      flash[:flash_error] = "Milestone already completed"
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    @milestone.completed_on = Time.now.utc
    @milestone.completed_by = @logged_user
    
    if not @milestone.save
      flash[:flash_error] = "Error saving"
    else
      ApplicationLog::new_log(@milestone, @logged_user, :close)
    end
    
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end
  
  def open
    if not @milestone.status_can_be_changed_by(@logged_user)
      flash[:flash_error] = "Insufficient permissions"
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    if @milestone.completed_by.nil?
      flash[:flash_error] = "Milestone already open"
      redirect_back_or_default :controller => 'milestone'
      return
    end
    
    @milestone.completed_on = 0
    @milestone.completed_by = nil
    
    if not @milestone.save
      flash[:flash_error] = "Error saving"
    else
      ApplicationLog::new_log(@milestone, @logged_user, :open, @milestone.is_private)
    end
    
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end
  
private

  def obtain_milestone
    begin
      @milestone = ProjectMilestone.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:flash_error] = "Invalid milestone"
      redirect_back_or_default :controller => 'milestone'
      return false
    end
    
    return true
  end
end