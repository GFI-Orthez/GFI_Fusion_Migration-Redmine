class SourceGroupUser < ActiveRecord::Base
  include SecondDatabase
  set_table_name :groups_users

  def self.migrate
  
  end

end
