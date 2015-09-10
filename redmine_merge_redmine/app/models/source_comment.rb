class SourceComment < ActiveRecord::Base
  include SecondDatabase
  set_table_name :comments
  #belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  def self.migrate
    compteur = 0
    puts "Fusion table Comments EN COURS..."
    all.each do |source_comment|
	#puts "Comment (UserId) : #{source_comment.author_id}"
	#puts "Comment (UserIdFusion) : #{RedmineMerge::Mapper.get_new_user_id(source_comment.author_id}"
	compteur+=1
	Comment.create!(source_comment.attributes) do |c|
	    c.author = User.find(RedmineMerge::Mapper.get_new_user_id(source_comment.author_id))
        end
    end
    puts "Fusion table Comments TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
