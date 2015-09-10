class SourceSetting < ActiveRecord::Base
  include SecondDatabase
  set_table_name :settings
  def self.migrate
    compteur = 0
    puts "Fusion table Settings EN COURS..."
    all.each do |source_setting|
	if Setting.find_by_name(source_setting.name)
	    next
        else
    	    compteur+=1
    	    Setting.create!(source_setting.attributes) do |s|
    		s.name = source_setting.name
		s.value = source_setting.value
		#puts "Setting Name : #{s.name} ID : #{s.id}"
	    end
	end
    end
    puts "Fusion table Settings TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end