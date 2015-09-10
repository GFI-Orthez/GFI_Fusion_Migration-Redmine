class SourceWikiContentObserver < ActiveRecord::Base
  include SecondDatabase
  set_table_name :wiki_content_versions

end
