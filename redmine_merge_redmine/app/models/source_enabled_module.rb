class SourceEnabledModule < ActiveRecord::Base
  include SecondDatabase
  set_table_name :enabled_modules

  def self.migrate
    all.each do |source_en|
      EnabledModule.create!(source_en.attributes) do |e|
        #puts "ID Project Enabled_modules : #{source_en.project_id}"
        e.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_en.project_id))
        #puts "Done !"
      end
    end
  end
end
