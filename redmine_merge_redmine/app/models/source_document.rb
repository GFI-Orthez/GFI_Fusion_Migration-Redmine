class SourceDocument < ActiveRecord::Base
  include SecondDatabase
  set_table_name :documents

  belongs_to :category, :class_name => 'SourceEnumeration', :foreign_key => 'category_id'

  def self.migrate
    compteur = 0
    puts "Fusion table Documents EN COURS..."
    all.each do |source_document|
      #puts "ID Document : #{source_document.id}"
      #puts "ID Projet Document : #{source_document.project_id}"
      compteur+=1
      document = Document.create!(source_document.attributes) do |d|
        d.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_document.project_id))
        d.category = DocumentCategory.find_by_name(source_document.category.name)
      end
      RedmineMerge::Mapper.add_document(source_document.id, document.id)
    end
    puts "Fusion table Documents TERMINE"
    puts "#{compteur} élément(s) fusionné(s)"
    puts ""
  end
end
