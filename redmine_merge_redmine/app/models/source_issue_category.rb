class SourceIssueCategory < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issue_categories

  def self.migrate
    compteur = 0
    puts "Fusion table Issue_category EN COURS..."
    all.each do |source_issue_category|
      next if IssueCategory.find_by_name_and_project_id(source_issue_category.name, source_issue_category.project_id)
      #puts "ID Catagorie : #{source_issue_category.id}"
      #puts "TEST : #{RedmineMerge::Mapper.get_new_project_id(source_issue_category.project_id)}"
      compteur+=1
      IssueCategory.create!(source_issue_category.attributes) do |ic|
        ic.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_issue_category.project_id))
      #puts "Done !"
      end
    end
    puts "Fusion table Issue_category TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
