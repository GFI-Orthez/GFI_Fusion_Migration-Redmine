class SourceCustomField < ActiveRecord::Base
  include SecondDatabase
  set_table_name :custom_fields

  def self.migrate
    compteur = 0
    puts "Fusion table Custom_fields EN COURS..."
    all.each do |source_custom_field|
      next if CustomField.find_by_name(source_custom_field.name)
      compteur+=1
      CustomField.create!(source_custom_field.attributes)
    end
    puts "Fusion table Custom_fields TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
