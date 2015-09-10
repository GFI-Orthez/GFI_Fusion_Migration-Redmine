class SourceMembers < ActiveRecord::Base
  include SecondDatabase
  set_table_name :members

end
