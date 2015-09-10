class SourceCustomValue < ActiveRecord::Base
  include SecondDatabase
  set_table_name :custom_values

  def self.migrate
    all.each do |source_custom_value|
      next if CustomValue.find_by_name(source_custom_value.name)

      CustomValue.create!(source_custom_value.attributes)
    end
  end
end
