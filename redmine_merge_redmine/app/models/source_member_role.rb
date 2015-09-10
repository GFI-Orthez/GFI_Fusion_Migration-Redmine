class SourceMemberRole < ActiveRecord::Base
  include SecondDatabase
  set_table_name :member_roles

end
