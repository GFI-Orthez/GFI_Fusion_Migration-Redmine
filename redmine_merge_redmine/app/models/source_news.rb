class SourceNews < ActiveRecord::Base
  include SecondDatabase
  set_table_name :news

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'

  def self.migrate
    compteur = 0
    puts "Fusion table News EN COURS..."
    all.each do |source_news|
      compteur+=1
      News.create!(source_news.attributes) do |n|
        #puts "ID Project NEWS : #{source_news.project_id}"
        #puts "Login User NEWS : #{source_news.author.login}"
        n.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_news.project_id))
        n.author = User.find_by_login(source_news.author.login)
        #puts "Done !"
      end
    end
    puts "Fusion table News TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
