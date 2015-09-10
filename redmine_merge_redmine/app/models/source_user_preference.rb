class SourceUserPreference < ActiveRecord::Base
  include SecondDatabase
  set_table_name :user_preferences

end