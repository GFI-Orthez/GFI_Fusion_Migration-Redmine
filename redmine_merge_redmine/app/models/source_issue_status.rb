class SourceIssueStatus < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issue_statuses

  def self.migrate
    compteur = 0
    puts "Fusion table Issue_statuses EN COURS..."
    all.each do |source_issue_status|
      next if IssueStatus.find_by_name(source_issue_status.name)
      compteur+=1
      IssueStatus.create!(source_issue_status.attributes)
    end
    puts "Fusion table Issue_statuses TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
