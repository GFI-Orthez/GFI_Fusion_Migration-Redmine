class SourceTracker < ActiveRecord::Base
  include SecondDatabase
  set_table_name :trackers

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'projects_trackers', :foreign_key => 'tracker_id', :association_foreign_key => 'project_id'

  def self.migrate
    compteur = 0
    puts "Fusion table Trackers EN COURS..."
    all.each do |source_tracker|
      next if Tracker.find_by_name(source_tracker.name)
      compteur+=1
      tracker = Tracker.create!(source_tracker.attributes)
      RedmineMerge::Mapper.add_tracker(source_tracker.id, tracker.id)
    end
    puts "Fusion table Trackers TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
