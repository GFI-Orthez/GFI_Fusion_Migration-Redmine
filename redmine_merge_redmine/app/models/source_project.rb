class SourceProject < ActiveRecord::Base
  include SecondDatabase
  set_table_name :projects

  has_many :enabled_modules, :class_name => 'SourceEnabledModule', :foreign_key => 'project_id'
  has_and_belongs_to_many :trackers, :class_name => 'SourceTracker', :join_table => 'projects_trackers', :foreign_key => 'project_id', :association_foreign_key => 'tracker_id'
  
  def self.migrate
    compteur = 0
    puts "Fusion table Projects EN COURS... (la fusion de cette table peut durer plusieurs minutes)"
    puts "La fusion des tables Custom_values, Projects_trackers et Wikis s'effectue en même temps"
    
    all(:order => 'lft ASC').each do |source_project|
      
      if Project.find_by_identifier(source_project.identifier)       
      
        if Project.find_by_name(source_project.name)
    	    RedmineMerge::Mapper.add_project(source_project.id, source_project.id)
    	    next
        end
      
      elsif Project.find_by_name(source_project.name)
        
        if Project.find_by_identifier(source_project.identifier)
    	    RedmineMerge::Mapper.add_project(source_project.id, source_project.id)
    	    next
        end
      end
      compteur+=1
      project = Project.create!(source_project.attributes) do |p|
    	    p.status = source_project.status
    	    if source_project.enabled_modules
        	p.enabled_module_names = source_project.enabled_modules.collect(&:name)
    	    end

    	    if source_project.trackers
        	source_project.trackers.each do |source_tracker|
        	    merged_tracker = Tracker.find_by_name(source_tracker.name)
        	    p.trackers << merged_tracker if merged_tracker
        	end
	    end
    	end 
    	
    	# Parent/child projects
      if source_project.parent_id
        project.set_parent!(Project.find_by_id(RedmineMerge::Mapper.get_new_project_id(source_project.parent_id)))
      end
      RedmineMerge::Mapper.add_project(source_project.id, project.id)
     end
     puts "Fusion table Projects TERMINE"
     puts "#{compteur} élément(s) fusionné(s)"
     puts ""
  end
end
