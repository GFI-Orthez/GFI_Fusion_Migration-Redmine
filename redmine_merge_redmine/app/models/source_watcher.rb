class SourceWatchers < ActiveRecord::Base
  include SecondDatabase
  set_table_name :watchers

end