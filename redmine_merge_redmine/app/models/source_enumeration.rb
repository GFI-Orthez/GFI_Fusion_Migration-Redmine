class SourceEnumeration < ActiveRecord::Base
  include SecondDatabase
  set_table_name :enumerations

  def self.migrate_issue_priorities
    compteur = 0
    puts "Fusion table Enumérations (IssuePriority) EN COURS ..."
    all(:conditions => {:type => "IssuePriority"}) .each do |source_issue_priority|
      next if IssuePriority.find_by_name(source_issue_priority.name)
      compteur+=1
      IssuePriority.create!(source_issue_priority.attributes)
    end
    puts "Fusion table Enumerations (IssuePriority) TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end

  def self.migrate_time_entry_activities
    compteur = 0
    puts "Fusion table Enumérations (TimeEntryActiviy) EN COURS ..."
    all(:conditions => {:type => "TimeEntryActivity"}) .each do |source_activity|
      next if TimeEntryActivity.find_by_name(source_activity.name)
      compteur+=1
      TimeEntryActivity.create!(source_activity.attributes)
    end
    puts "Fusion table Enumerations (TimeEntryActivity) TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end

  def self.migrate_document_categories
    compteur = 0
    puts "Fusion table Enumérations (DocumentCategory) EN COURS ..."
    all(:conditions => {:type => "DocumentCategory"}) .each do |source_document_category|
      next if DocumentCategory.find_by_name(source_document_category.name)
      compteur+=1
      DocumentCategory.create!(source_document_category.attributes)
    end
    puts "Fusion table Enumerations (DocumentCategory) TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end

end
