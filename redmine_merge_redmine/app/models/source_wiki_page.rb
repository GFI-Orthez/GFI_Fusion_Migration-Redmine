class SourceWikiPage < ActiveRecord::Base
  include SecondDatabase
  set_table_name :wiki_pages

  def self.migrate
    all(:order => 'parent_id ASC').each do |source_wiki_page|
      puts "ID WIKI PAGE #{source_wiki_page.id}"
      wiki_page = WikiPage.create!(source_wiki_page.attributes) do |wp|
        puts "ID WIKI SOURCE associé #{source_wiki_page.wiki_id}"
        wp.wiki = Wiki.find(RedmineMerge::Mapper.get_new_wiki_id(source_wiki_page.wiki_id))
        puts "Test parent"
        if source_wiki_page.parent_id!=nil
    	    puts "PARENT"
    	    wp.parent = WikiPage.find(RedmineMerge::Mapper.get_new_wiki_page_id(source_wiki_page.parent_id))
        else
    	    puts "PAS DE PARENT"
        end
        
        #wp.parent = WikiPage.find(RedmineMerge::Mapper.get_new_wiki_page_ id(source_wiki_page.parent_id)) if source_wiki_page.parent_id
      end

      RedmineMerge::Mapper.add_wiki_page(source_wiki_page.id, wiki_page.id)
    end
  end
end
