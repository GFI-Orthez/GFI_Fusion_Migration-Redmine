class SourceProjectTracker < ActiveRecord::Base
  include SecondDatabase
  set_table_name :projects_trackers

  def self.migrate
    all.each do |source_pt|
      ProjectTracker.create!(source_pt.attributes) do |pt|
        #puts "ID Project Tracker : #{source_pt.id}"
        pt.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_pt.project_id))
        pt.tracker = Tracker.find_by(RedmineMerge::Mapper.get_new_tracker_id(source_pt.tracker_id))
        #puts "Done !"
      end
    end
  end
end
