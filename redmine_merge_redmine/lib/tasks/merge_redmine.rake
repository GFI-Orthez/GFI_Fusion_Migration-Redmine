namespace :redmine do
  desc 'Report on the data in the target database'
  task :data_report => :environment do
    [
     #User,
     CustomField,
     Tracker,
     IssueStatus,
     Enumeration,
     Comment,
     #Group,
     Token,
     UserPreference,
     Watcher,
     Setting,
     #SchemaMigration,
     Role,
     Project,
     EnabledModule,
     #ProjectTracker,
     Member,
     MemberRole,
     Query,
     Version,
     News,
     IssueCategory,
     Issue,
     Journal,
     JournalDetail,
     TimeEntry,
     Document,
     Wiki,
     WikiPage,
     WikiContent,
     #WikiContentObserver,
     Attachment,
     Workflow
    ].each do |model|
      puts "#{model}: #{model.count}"
    end
  end
  
  desc 'Merge two Redmine databases'
  task :merge_redmine => :environment do
    RedmineMerge.migrate
  end
end
