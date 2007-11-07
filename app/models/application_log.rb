=begin
RailsCollab
-----------

=end

class ApplicationLog < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :taken_by, :class_name => 'User', :foreign_key => 'taken_by_id'
  belongs_to :rel_object, :polymorphic => true
  
  before_create :process_params
	 
  def process_params
    write_attribute("created_on", Time.now.utc)
  end
  
  def friendly_action
    case self.action
      when :add
        return "Added"
      when :delete
        return "Deleted"
      when :edit
        return "Modified"
      when :open
        return "Reopened"
      when :close
        return "Closed"
    end
  end
  
  def is_today?
    return (self.created_on.to_date >= Date.today and self.created_on.to_date < Date.today+1)
  end
  
  def is_yesterday?
    return (self.created_on.to_date >= Date.today-1 and self.created_on.to_date < Date.today)
  end
     
  def self.new_log(obj, user, action, private=false, real_project=nil)
    really_silent = action == :delete
    if not really_silent
      # Lets go...
      @log = ApplicationLog.new()
      
      @log.action = action
      if action == :delete
        @log.rel_object_id = nil
        @log.rel_object_type = obj.class.to_s
      else
        @log.rel_object = obj
      end
      @log.object_name = obj.object_name
      
      @log.project = nil
      if real_project.nil?
        if obj.is_a?(Project)
          @log.project = obj unless action == :delete
        elsif [ProjectMilestone,ProjectMessage,ProjectTaskList,ProjectTime,ProjectForm,ProjectFile,ProjectFolder].include?(obj.class)
          @log.project = obj.project
        end
      else
        @log.project = real_project
      end
      
      @log.created_by = user
      if not user.nil?
        user.last_activity = Time.now.utc
        user.save
      end
      @log.taken_by = user
      @log.is_private = private
      @log.save
    end
  end
  
  def self.logs_for(project, include_private, include_silent, limit=50)
  	if project.class == Array
  		project_ids = project.collect do |p|
			p.id
		end.join ','
		
		if project_ids.length == 0
			return []
		end
		
		conditions = "project_id IN (#{project_ids})"
  	else
  		conditions = "project_id = #{project.id}"
  	end
  	
  	private_conditions = " "
  	private_conditions += "AND is_private = 0 " unless include_private
  	private_conditions += "AND is_silent = 0" unless include_silent
  	
  	ApplicationLog.find(:all, :conditions => "#{conditions}#{private_conditions}", :order => 'created_on DESC', :limit => limit)
  end
end