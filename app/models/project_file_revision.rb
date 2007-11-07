=begin
RailsCollab
-----------

=end

class ProjectFileRevision < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project_file, :foreign_key => 'file_id'
	belongs_to :file_type, :foreign_key => 'file_type_id'

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
	
	before_create :process_params
	before_update :process_update_params
	before_destroy :process_destroy
	 
	def process_params
	  write_attribute("created_on", Time.now.utc)
	end
	
	def process_update_params
	  write_attribute("updated_on", Time.now.utc)
	end
	
	def process_destroy
		# Destroy FileRepo entries
		FileRepo.handle_delete(self.repository_id)
	end
	
	def upload_file
		nil
	end
	
	def upload_file=(value)
		self.filesize = value.size
		self.type_string = value.content_type.chomp
		
		extension = value.original_filename.slice(".*")
		if extension
			begin
				self.file_type = FileType.find(:first, :conditions => ['extension = ?', extension])
			rescue ActiveRecord::RecordNotFound
				self.file_type = FileType.find(:first, :conditions => 'extension = \'unknown\'')
			end
		end
		
		if self.new_record?
			self.repository_id = FileRepo.handle_storage(value.read)
		else
			self.repository_id = FileRepo.handle_update(self.repository_id, value.read)
		end
	end
	
	def update_thumb
		# TODO
	end
	
	def thumb_url
		name = "unknown.png"
		return "/images/filetypes/#{name}"
	end
		
	def object_name
		self.name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'file', :action => 'browse_folder', :id => self.id, :active_project => self.project_id
	end
	
	def icon_url
		name = "unknown.png"
		return "/filetypes/#{name}"
	end
	
	# Validation
	
	#validates_presence_of :repository_id
end