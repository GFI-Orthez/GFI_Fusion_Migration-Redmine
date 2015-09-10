class SourceToken < ActiveRecord::Base
  include SecondDatabase
  set_table_name :tokens
  def self.migrate
    puts "Fusion de la table tokens"
    all.each do |source_token|
      Token.create!(source_token.attributes) do |t|
        #puts "TOKEN (UserID source) : #{source_token.user_id}"
	t.user = User.find(RedmineMerge::Mapper.get_new_user_id(source_token.user_id))
	#puts "ok !" 
      end
    end
  end
end
