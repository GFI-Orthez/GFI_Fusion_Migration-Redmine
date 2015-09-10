class SourceQuery < ActiveRecord::Base
  include SecondDatabase
  set_table_name :queries

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'user_id'

  def self.migrate
    compteur = 0
    puts "Fusion table Queries EN COURS..."
    all.each do |source_queries|
      compteur+=1
      Query.create!(source_queries.attributes) do |q|
        #puts "ID Project QUERIES : #{source_queries.project_id}"
        #puts "Login User QUERIES : #{source_queries.user_id}"
        q.user = User.find(RedmineMerge::Mapper.get_new_user_id(source_queries.user_id))
        q.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_queries.project_id))
      end
    end
    puts "Fusion table Queries TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
