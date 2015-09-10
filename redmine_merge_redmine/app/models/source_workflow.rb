class SourceWorkflows < ActiveRecord::Base
  include SecondDatabase
  set_table_name :workflows
  def self.migrate
    puts "Fusion table workflows"
    all.each do |source_w|
	Workflow.create!(source_w.attributes) do |w|
	    puts "Workflows source ID : {source_w.id}"
	    w.tracker_id=Tracker.find(RedmineMerge::Mapper.get_new_tracker_id(source_w.tracker_id))
	    w.new_status_id=Enumerations

end
