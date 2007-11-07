=begin
RailsCollab
-----------

=end

class DashboardController < ApplicationController
    
    before_filter :login_required
    after_filter  :user_track
    	
	def index
	    @active_projects = @logged_user.active_projects
		
		if @active_projects.length > 0
			include_private = @logged_user.member_of_owner?
			
			project_ids = @active_projects.collect do |i|
				i.id
			end.join','
			
			@activity_log = ApplicationLog.find(:all, :conditions => "project_id in (#{project_ids}) #{include_private ? '' : 'AND is_private = false'}", :order => 'created_on DESC, id DESC', :limit => AppConfig.project_logs_per_page)
	    else
			@activity_log = []
		end
		
		@today_milestones = @logged_user.todays_milestones
		@late_milestones = @logged_user.late_milestones
		
		@online_users = User.get_online()
		@my_projects = @active_projects
		@content_for_sidebar = 'index_sidebar'
	end
	
	def my_projects
		@active_projects = @logged_user.active_projects
		
		# Create the sorted projects list
		sort_type = params[:orderBy]
		sort_type = 'priority' unless ['name'].include?(params[:orderBy])
		@sorted_projects = @active_projects.sort_by { |item|
			item[sort_type].nil? ? 0 : item[sort_type]
		}
		
		@finished_projects = @logged_user.finished_projects
		@content_for_sidebar = 'my_projects_sidebar'
	end
	
	def my_tasks
		@active_projects = @logged_user.active_projects
	    @has_assigned_tasks = nil
        @projects_milestonestasks = @active_projects.collect do |project|
          @has_assigned_tasks ||= true unless (project.milestones_by_user(@logged_user).length == 0 and  project.tasks_by_user(@logged_user).length == 0)
          {:name => project.name, :id => project.id, :milestones => project.milestones_by_user(@logged_user), :tasks => project.tasks_by_user(@logged_user)}
        end
        @has_assigned_tasks ||= false
        
		@content_for_sidebar = 'my_tasks_sidebar'
	end
end