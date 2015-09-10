class SourceVersion < ActiveRecord::Base
  include SecondDatabase
  set_table_name :versions

  def self.migrate
    compteur = 0
    puts "Fusion table Versions EN COURS..."
    all.each do |source_version|
      #puts "ID Project Version Source : #{source_version.project_id}"
      compteur+=1
      version = Version.create!(source_version.attributes) do |v|
      #puts "TEST #{RedmineMerge::Mapper.get_new_project_id(source_version.project_id)}"
        v.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_version.project_id))
      end
      RedmineMerge::Mapper.add_version(source_version.id, version.id)
    end
    puts "Fusion table Versions TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
