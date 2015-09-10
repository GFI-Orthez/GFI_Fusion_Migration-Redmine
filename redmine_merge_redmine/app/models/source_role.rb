class SourceRole < ActiveRecord::Base
  include SecondDatabase
  set_table_name :roles

end
