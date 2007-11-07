=begin
RailsCollab
-----------

=end

module DashboardHelper
	def dashboard_tabbed_navigation(current=0)
	 items = [{:id => 0, :title => 'Overview', :url => '/dashboard/index', :selected => false},
		{:id => 1, :title => 'My projects', :url => '/dashboard/my_projects', :selected => false},
		{:id => 2, :title => 'My tasks', :url => '/dashboard/my_tasks', :selected => false}]
		
		items[current][:selected] = true
		return items
	end
	
	def dashboard_crumbs(current="Overview")
	 [{:title => 'Dashboard', :url => '/dashboard'},
	  {:title => current}]
	end
	
	def new_account_steps(user)
	 [{:title => "Step 1: Update your company info",
	   :content => "<a href='/company/edit'>Set your company details</a> such as phone and fax number, address, email, homepage etc",
	   :del => Company.owner.updated?},
	  {:title => "Step 2: Add team members",
	   :content => "You can <a href='/user/add?company_id=#{user.company.id}'>create user accounts</a> for all members of your team (unlimited number). Every member will get their username and password which they can use to access the system",
	   :del => (Company.owner.users.length > 1)},
	  {:title => "Step 3: Add client companies and their members",
	   :content => "Now its time to <a href='/company/add_client'>define client companies</a> (unlimited). When you're done you can add their members or leave that for their team leaders. Client members are similar to your company members except that they have limited access to content and functions (you can set what they can do per project and per member)",
	   :del => (Company.owner.clients.length > 0)},
	  {:title => "Step 4: Start a project",
	   :content => "Defining a <a href='/project/add'>new project</a> is really easy: set a name and decription (optional) and click submit. After that you can set permissions for your team members and clients.",
	   :del => (Company.owner.projects.length > 0)}]
	end
end