class SourceSchemaMigration < ActiveRecord::Base
  include SecondDatabase
  set_table_name :schema_migrations
  def self.migrate
    puts "Fusion de la table schema_migrations"
    all.each do |source_schema|
	next if SchemaMigration.find_by_version(source_schema.version)
        SchemaMigration.create!(source_schema.attributes) do |s|
    	    s.version = source_schema.version
    	    #puts "Schema Name : #{s.name} ID : #{s.id}"
    	end
    end
  end
end