class SourceUser < ActiveRecord::Base
  include SecondDatabase
  set_table_name :users

  def self.migrate
    compteur = 0
    puts "Fusion table Users EN COURS..."
    RedmineMerge::Mapper.add_user(2, 2) #Utilisateur anonyme  
    all.each do |source_user|
      if User.find_by_mail(source_user.mail)
        RedmineMerge::Mapper.add_user(source_user.id, User.find_by_login(source_user.login).id)
        next
      end
      if User.find_by_login(source_user.login)
        RedmineMerge::Mapper.add_user(source_user.id, User.find_by_login(source_user.login).id)
        next
      end
      next if source_user.type == "AnonymousUser"
      compteur+=1
      user = User.create!(source_user.attributes) do |u|
        u.login = source_user.login
        u.admin = source_user.admin
        u.hashed_password = source_user.hashed_password
      end
      RedmineMerge::Mapper.add_user(source_user.id, user.id)
    end
    puts "Fusion table Users TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
