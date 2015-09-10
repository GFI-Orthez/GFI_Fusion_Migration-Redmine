/*
Fusion semi-automatique de deux bases Redmine

Script SQL permettant de fusionner des tables en mettant à jour la clé primaire et en faisant correspondre les clés étrangères
Ce script a été rédigé pour répondre a un besoin spécifique et doit être adapté en conséquence.

*/
--  On desactive le safe update mode pour pouvoir effectuer des updates sur toute une table sans condition
SET SQL_SAFE_UPDATES = 0;

-- Fusion table Schéma_migrations
INSERT INTO bitnami_redmine.schema_migrations 
(SELECT DISTINCT n.version FROM niort_redmine.schema_migrations n where n.version NOT IN 
(SELECT DISTINCT o.version FROM bitnami_redmine.schema_migrations o));

-- Fusion table Tokens
SET @MaxTokens =(select GREATEST( (select max(id) from bitnami_redmine.tokens), (select max(id) from niort_redmine.tokens) ));
UPDATE niort_redmine.tokens source
SET source.id = source.id + @MaxTokens,
source.user_id = (SELECT id FROM bitnami_redmine.users where login =
(select login from niort_redmine.users where id=source.user_id));
INSERT INTO bitnami_redmine.tokens SELECT * FROM niort_redmine.tokens;

-- Dans les tables de la base source, on augment les id, on met à jour les clés étrangères et on insère dans la table correspondante de la base destination
-- L'ordre a une importance puisque la mise à jour des clés étrangère doit se faire une fois que la table référencée a été fusionnée
-- Fusion table Groups_users
-- On augmente l'id de tous les users de type 'Group' dans la base source
SET @indexActuel=(SELECT max(id) FROM bitnami_redmine.users);
UPDATE niort_redmine.users
SET id = id + @indexActuel WHERE type='Group';

-- On insère tous les users de type 'Group' dans la base destination. Pas de problème de clé primaire puisque les id ont été augmentés
INSERT INTO bitnami_redmine.users SELECT * FROM niort_redmine.users where type='Group';

-- Maintenant que tous les users (Users, Group et Anonymous) ont été fusionnés, on peut fusionner la table groups_users sans problème
UPDATE niort_redmine.groups_users
SET group_id =(SELECT id FROM bitnami_redmine.users where lastname =
(select lastname from niort_redmine.users where id=group_id+@indexActuel)),
user_id=(SELECT id FROM bitnami_redmine.users where login =
(select login from niort_redmine.users where id=user_id));
INSERT INTO bitnami_redmine.groups_users SELECT * FROM niort_redmine.groups_users;

-- Fusion table User_preferences
SET @maxUpref = (select GREATEST( (select max(id) from bitnami_redmine.user_preferences), (select max(id) from niort_redmine.user_preferences) ));
UPDATE niort_redmine.user_preferences source
SET source.id = source.id +  @maxUpref,
source.user_id=(SELECT id FROM bitnami_redmine.users dest where
login=(select login from niort_redmine.users where id=source.user_id) and
lastname = (select lastname from niort_redmine.users where id=source.user_id)) ;
INSERT INTO bitnami_redmine.user_preferences SELECT * FROM niort_redmine.user_preferences
where user_id NOT IN (select user_id from bitnami_redmine.user_preferences);

-- Fusion table Watchers
SET @maxWatchers= (select GREATEST( (select max(id) from bitnami_redmine.watchers), (select max(id) from niort_redmine.watchers) ));
UPDATE niort_redmine.watchers
SET id = id + @maxWatchers,
user_id=(SELECT id FROM bitnami_redmine.users where login =
(select login from niort_redmine.users where id=user_id) );
INSERT INTO bitnami_redmine.watchers SELECT * FROM niort_redmine.watchers;

-- Fusion table Roles
SET @maxRoles = (select GREATEST( (select max(id) from bitnami_redmine.roles), (select max(id) from niort_redmine.roles) ));
UPDATE niort_redmine.roles
SET id = id + @maxRoles;
INSERT INTO bitnami_redmine.roles SELECT * FROM niort_redmine.roles source where
source.name NOT IN(select name from bitnami_redmine.roles);

-- Fusion table Enabled_modules
SET @maxEN = (select GREATEST( (select max(id) from bitnami_redmine.enabled_modules), (select max(id) from niort_redmine.enabled_modules) ));
UPDATE niort_redmine.enabled_modules source
SET source.id = source.id + @maxEN,
source.project_id=(
SELECT id FROM bitnami_redmine.projects dest where dest.name =
	(select name from niort_redmine.projects where id=source.project_id)
    and dest.identifier = (select identifier from niort_redmine.projects where id=source.project_id)
);
INSERT INTO bitnami_redmine.enabled_modules SELECT * FROM niort_redmine.enabled_modules source
where source.id NOT IN (
select source.id from bitnami_redmine.enabled_modules dest
where dest.name=source.name and dest.project_id=source.project_id);

-- Fusion table Members
-- On met à jour les user_id qui référencent un user de type 'Group'
UPDATE niort_redmine.members source
SET source.user_id = source.user_id + @indexActuel where source.user_id NOT IN (select id from niort_redmine.users where type='Anonymous' or type='User');
-- Puis on procède à la fusion de la table members
SET	@MaxMembers= (select GREATEST( (select max(id) from bitnami_redmine.members), (select max(id) from niort_redmine.members) ));
UPDATE niort_redmine.members source
SET source.id = source.id +	@MaxMembers,
source.project_id=(SELECT dest.id FROM bitnami_redmine.projects dest where dest.name = (select name from niort_redmine.projects where id=source.project_id)  and dest.identifier = (select identifier from niort_redmine.projects where id=source.project_id)), 
source.user_id=(SELECT id FROM bitnami_redmine.users dest where
login=(select login from niort_redmine.users where id=source.user_id) and
lastname = (select lastname from niort_redmine.users where id=source.user_id))
order by source.id DESC;
INSERT INTO bitnami_redmine.members SELECT * FROM niort_redmine.members where id + @MaxMembers NOT IN (
select source.id from niort_redmine.members source, bitnami_redmine.members dest
where source.user_id =(select id from niort_redmine.users where
login = (select login from bitnami_redmine.users where id=dest.user_id) and 
lastname = (select lastname from bitnami_redmine.users where id=dest.user_id)) and
source.project_id= 
(select n.id from niort_redmine.projects n 
where n.identifier= (select identifier from bitnami_redmine.projects where id= dest.project_id) and
n.name= (select name from bitnami_redmine.projects where id=dest.project_id)));

-- Fusion table Member_roles
set @maxMRoles =  (select GREATEST( (select max(id) from bitnami_redmine.member_roles), (select max(id) from niort_redmine.member_roles) ));
UPDATE niort_redmine.member_roles source
SET source.id = source.id + @maxMRoles,
source.member_id = source.member_id + @MaxMembers,
source.role_id = (select id from bitnami_redmine.roles where name =
	(select name from niort_redmine.roles where id=source.role_id + @maxRoles)
),
source.inherited_from = source.inherited_from + @maxMRoles;
INSERT INTO bitnami_redmine.member_roles SELECT * from niort_redmine.member_roles;

-- Fusion table Workflows
SET @maxWorkflows = (select GREATEST( (select max(id) from bitnami_redmine.workflows), (select max(id) from niort_redmine.workflows) ));
UPDATE niort_redmine.workflows source
SET source.id = source.id + @maxWorkflows,
source.role_id = (select id from bitnami_redmine.roles where name =
	(select name from niort_redmine.roles where id=source.role_id + @maxRoles)
),
source.tracker_id = (select id from bitnami_redmine.trackers where name = (select name from niort_redmine.trackers where id=source.tracker_id)),
source.new_status_id = (select dest.id from bitnami_redmine.enumerations dest, niort_redmine.enumerations source2 where 
	dest.name =	source2.name and dest.type=source2.type and source2.id = source.new_status_id),
source.old_status_id = (select dest.id from bitnami_redmine.enumerations dest, niort_redmine.enumerations source2 where 
	dest.name =	source2.name and dest.type=source2.type and source2.id = source.old_status_id
);
INSERT INTO bitnami_redmine.workflows SELECT * FROM niort_redmine.workflows;

-- Fusion table Wikis (quelques wikis n'ont pas été fusionné par le plugin, donc on met tout à jour, on insère tout et on active une contrainte d'unicité pour supprimer les doublons)
SET @maxWikis = (select GREATEST( (select max(id) from bitnami_redmine.wikis), (select max(id) from niort_redmine.wikis) ));
UPDATE niort_redmine.wikis source
SET source.id = source.id + @maxWikis,
source.project_id = (select id from bitnami_redmine.projects where
    identifier = (select identifier from niort_redmine.projects where id=source.project_id)
);
INSERT INTO bitnami_redmine.wikis select * from niort_redmine.wikis;

-- Correction particulière. Le wiki qui référence le projet Abscence est a supprimer car les projets GCT sont à fusionner avec les projets GCT originaux.
-- Sans cette correction, on obtient 1 wiki de trop par rapport à ce qui était prévu
UPDATE bitnami_redmine.wikis source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (select max(id) from bitnami_redmine.projects where name in ("GCT - ACTIVITES INTERNES", "Absences", "Mandat", "Formation", "Divers") group by name);

-- On élimine les potentiels doublons
ALTER IGNORE TABLE bitnami_redmine.wikis ADD UNIQUE INDEX wikis_unique (project_id);
alter table bitnami_redmine.wikis drop index wikis_unique;

-- On remet la table wikis dans l'état initial. Cet état permet de faire les lien entre les projets et les tables référençant la table wikis.
UPDATE niort_redmine.wikis source
SET source.id = source.id - @maxWikis,
source.project_id = (select id from niort_redmine.projects where
    identifier = (select identifier from bitnami_redmine.projects where id=source.project_id)
);

-- Fusion table Wiki_pages
SET @maxIdWikiPages = (select GREATEST( (select max(id) from bitnami_redmine.wiki_pages), (select max(id) from niort_redmine.wiki_pages) ));
UPDATE niort_redmine.wiki_pages source
SET source.id = source.id + @maxIdWikiPages,
source.wiki_id = (select id from bitnami_redmine.wikis where project_id=
					(select id from bitnami_redmine.projects where identifier=
						(select identifier from niort_redmine.projects where id=
							(select project_id from niort_redmine.wikis where id=source.wiki_id))));
INSERT INTO bitnami_redmine.wiki_pages SELECT * FROM niort_redmine.wiki_pages;

-- Fusion table Wiki_contents
SET @maxIdWikiContents = (select GREATEST( (select max(id) from bitnami_redmine.wiki_contents), (select max(id) from niort_redmine.wiki_contents) ));
UPDATE niort_redmine.wiki_contents source
SET source.id = source.id + @maxIdWikiContents,
source.author_id =(SELECT id FROM bitnami_redmine.users dest where login=(select login from niort_redmine.users where id=source.author_id)),
source.page_id = source.page_id + @maxIdWikiPages;

INSERT INTO bitnami_redmine.wiki_contents SELECT * FROM niort_redmine.wiki_contents;

-- Fusion table Wiki_content_versions
SET @MaxWCT = (select GREATEST( (select max(id) from bitnami_redmine.wiki_content_versions), (select max(id) from niort_redmine.wiki_content_versions) ));
UPDATE niort_redmine.wiki_content_versions source
SET source.id = source.id + @MaxWCT,
source.author_id=(SELECT dest.id FROM bitnami_redmine.users dest where dest.login=(select login from niort_redmine.users where id=source.author_id)),
source.wiki_content_id = source.wiki_content_id + @maxIdWikiContents,
source.page_id = source.page_id + @maxIdWikiPages;
INSERT INTO bitnami_redmine.wiki_content_versions SELECT * FROM niort_redmine.wiki_content_versions;

-- Fusion table Issues
SET @maxIdIssue = (select GREATEST( (select max(id) from bitnami_redmine.issues), (select max(id) from niort_redmine.issues) ));
UPDATE niort_redmine.issues source
SET source.id = source.id + @maxIdIssue,
source.tracker_id = (select id from bitnami_redmine.trackers where name = (select name from niort_redmine.trackers where id = source.tracker_id)),
source.project_id=(SELECT dest.id FROM bitnami_redmine.projects dest where 
	dest.name = (select name from niort_redmine.projects where id=source.project_id)  and 
	dest.identifier = (select identifier from niort_redmine.projects where id=source.project_id)), 
source.category_id = (select dest.id from bitnami_redmine.issue_categories dest, niort_redmine.issue_categories source2 where dest.project_id = 
(select id from bitnami_redmine.projects where name = (select name from niort_redmine.projects where id = source2.project_id) and
identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and dest.name=source2.name and source2.id=source.category_id),
source.status_id = (select id from bitnami_redmine.issue_statuses where name = (select name from niort_redmine.issue_statuses where id=source.status_id)),
source.assigned_to_id = (SELECT id FROM bitnami_redmine.users dest where login=(select login from niort_redmine.users where id=source.assigned_to_id)),
source.priority_id =  (select dest.id from bitnami_redmine.enumerations dest, niort_redmine.enumerations source2 where
 dest.name=source2.name and dest.type=source2.type and dest.position=source2.position and source.priority_id=source2.id),
source.fixed_version_id =  (select dest.id from bitnami_redmine.versions dest, niort_redmine.versions source2 where
 dest.name=source2.name and dest.project_id = (select id from bitnami_redmine.projects where
 name = (select name from niort_redmine.projects where id = source2.project_id) and 
 identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and source.fixed_version_id = source2.id),
source.author_id = (SELECT id FROM bitnami_redmine.users dest where login=(select login from niort_redmine.users where id=source.author_id)),
source.root_id = source.root_id + @maxIdIssue;
INSERT INTO bitnami_redmine.issues SELECT * FROM niort_redmine.issues;

-- Fusion table Journals
SET @maxIdJournal = (select GREATEST( (select max(id) from bitnami_redmine.journals), (select max(id) from niort_redmine.journals) ));
UPDATE niort_redmine.journals source
SET source.id = source.id + @maxIdJournal,
source.journalized_id = source.journalized_id + @maxIdIssue,
source.user_id = (SELECT id FROM bitnami_redmine.users dest where login=(select login from niort_redmine.users where id=source.user_id))
where source.journalized_type = 'Issue';
INSERT INTO bitnami_redmine.journals SELECT * FROM niort_redmine.journals;

-- Fusion table Time_entries
SET @maxTEntries = (select GREATEST( (select max(id) from bitnami_redmine.time_entries), (select max(id) from niort_redmine.time_entries) ));
UPDATE niort_redmine.time_entries source
SET source.id = source.id +  @maxTEntries,
source.project_id=(SELECT dest.id FROM bitnami_redmine.projects dest where 
	dest.name = (select name from niort_redmine.projects where id=source.project_id)  and 
	dest.identifier = (select identifier from niort_redmine.projects where id=source.project_id)), 
source.issue_id = source.issue_id+ @maxIdIssue,
source.user_id = (SELECT id FROM bitnami_redmine.users dest where login=(select login from niort_redmine.users where id=source.user_id)),
source.activity_id = (select id from bitnami_redmine.enumerations where name=(select name from niort_redmine.enumerations where id=source.activity_id)
and type=(select type from niort_redmine.enumerations where id=source.activity_id) and active=1);
INSERT INTO bitnami_redmine.time_entries SELECT * FROM niort_redmine.time_entries;

-- Fusion table Custom_fields_trackers
UPDATE niort_redmine.custom_fields_trackers source
SET source.custom_field_id = (select id from bitnami_redmine.custom_fields where
	type = (select type from niort_redmine.custom_fields where id = source.custom_field_id) and
    name = (select name from bitnami_redmine.custom_fields where id = source.custom_field_id)),
source.tracker_id = (select id from bitnami_redmine.trackers where name = (select name from niort_redmine.trackers where id=source.tracker_id));
INSERT INTO bitnami_redmine.custom_fields_trackers SELECT * FROM niort_redmine.custom_fields_trackers;

-- Fusion table Attachments (on distingue les cas car la table Attachments référence des Documents, des Issues et des wikiPages)
SET @maxAttachments = (select GREATEST( (select max(id) from bitnami_redmine.attachments), (select max(id) from niort_redmine.attachments) ));
UPDATE niort_redmine.attachments source
SET source.id = source.id + @maxAttachments,
source.container_id = source.container_id + (select max(id) from bitnami_redmine.documents) -  (select max(id) from niort_redmine.documents)
where source.container_type='Document';

UPDATE niort_redmine.attachments source
SET source.id = source.id + @maxAttachments,
source.container_id = source.container_id + @maxIdIssue
where source.container_type='Issue';

UPDATE niort_redmine.attachments source
SET source.id = source.id + @maxAttachments,
source.container_id = source.container_id + @maxIdWikiPages
where source.container_type='WikiPage';

INSERT INTO bitnami_redmine.attachments SELECT * from niort_redmine.attachments;

-- Fusion table Projects_trackers (pour ceux qui n'ont pas été fusionnés)
alter table niort_redmine.projects_trackers drop index projects_trackers_unique;
SET SQL_SAFE_UPDATES=0;
UPDATE niort_redmine.projects_trackers source
SET source.project_id = (select id from bitnami_redmine.projects where
	name = (select name from niort_redmine.projects where id=source.project_id) and
    identifier = (select identifier from niort_redmine.projects where id=source.project_id)),
source.tracker_id = (select id from bitnami_redmine.trackers where name=(select name from niort_redmine.trackers where id=source.tracker_id));
ALTER IGNORE TABLE niort_redmine.projects_trackers ADD UNIQUE INDEX projects_trackers_unique (project_id, tracker_id);
alter table bitnami_redmine.projects_trackers drop index projects_trackers_unique;
INSERT INTO bitnami_redmine.projects_trackers select * from niort_redmine.projects_trackers;
ALTER IGNORE TABLE bitnami_redmine.projects_trackers ADD UNIQUE INDEX projects_trackers_unique (project_id, tracker_id);

-- Fusion table Custom_values
ALTER IGNORE TABLE bitnami_redmine.custom_values ADD UNIQUE INDEX custom_values_unique (customized_type, customized_id, custom_field_id);
alter table bitnami_redmine.custom_values drop index custom_values_unique;

-- On fusionne les cutom_values dont le cutomized_type='Issue'
SET @MaxCValues = (select GREATEST( (select max(id) from bitnami_redmine.custom_values), (select max(id) from niort_redmine.custom_values) ));
UPDATE niort_redmine.custom_values source
SET source.id = source.id + @MaxCValues,
source.customized_id= source.customized_id + @maxIdIssue,
source.custom_field_id = (SELECT id FROM bitnami_redmine.custom_fields where name =
(select name from niort_redmine.custom_fields where id=custom_field_id))
where source.customized_type='Issue';
INSERT INTO bitnami_redmine.custom_values SELECT * FROM niort_redmine.custom_values where customized_type = 'Issue';

-- On update les custom_values dont le cutomized_type='Project'
SET @MaxCValues = (select GREATEST( (select max(id) from bitnami_redmine.custom_values), (select max(id) from niort_redmine.custom_values) ));
UPDATE niort_redmine.custom_values source
SET source.id = source.id + @MaxCValues,
source.customized_id= (select id from bitnami_redmine.projects where name=(select name from niort_redmine.projects where id=source.customized_id) and identifier=(select identifier from niort_redmine.projects where id=source.customized_id)),
source.custom_field_id = (SELECT id FROM bitnami_redmine.custom_fields where name =
(select name from niort_redmine.custom_fields where id=source.custom_field_id))
where source.customized_type='Project';

-- Les values des lignes dont le customized_type='Project' n'ont pas été mise à jour. Cette requête les met à jour.
UPDATE bitnami_redmine.custom_values dest
SET value=(select value from niort_redmine.custom_values source
where dest.custom_field_id=source.custom_field_id and source.customized_type=dest.customized_type and dest.customized_type='Project' and source.customized_id=dest.customized_id and value IS NOT NULL)
where dest.customized_id IN (select customized_id from niort_redmine.custom_values where customized_type='Project');

-- On update les cutom_values dont le cutomized_type='Principal'
SET @MaxCValues = (select GREATEST( (select max(id) from bitnami_redmine.custom_values), (select max(id) from niort_redmine.custom_values) ));
UPDATE niort_redmine.custom_values source
SET source.id = source.id + @MaxCValues,
source.customized_id= (select id from bitnami_redmine.users where login=(select login from niort_redmine.users where id=source.customized_id) and lastname=(select lastname from niort_redmine.users where id=source.customized_id)),
source.custom_field_id = (SELECT id FROM bitnami_redmine.custom_fields where name =
(select name from niort_redmine.custom_fields where id=source.custom_field_id))
where source.customized_type='Principal';

-- Les values des lignes dont le customized_type='Principal' n'ont pas été mise à jour. Cette requête les met à jour.
UPDATE bitnami_redmine.custom_values dest
SET value=(select value from niort_redmine.custom_values source
where dest.custom_field_id=source.custom_field_id and source.customized_type=dest.customized_type and dest.customized_type='Principal' and source.customized_id=dest.customized_id)
-- where dest.value='?' or dest.value IS NULL;
where (dest.value='?' or dest.value IS NULL or dest.value="") and dest.customized_type='Principal';

ALTER IGNORE TABLE bitnami_redmine.custom_values ADD UNIQUE INDEX custom_values_unique (customized_type, customized_id, custom_field_id);

-- Fusion table Journal_details (on distingue là aussi les cas)
UPDATE niort_redmine.journal_details source
SET source.old_value=(select id from bitnami_redmine.users where login=(select login from niort_redmine.users where id=source.old_value)
and lastname=(select lastname from niort_redmine.users where id=source.old_value))
where property='attr' and prop_key='assigned_to_id' and source.old_value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.value=(select id from bitnami_redmine.users where login=(select login from niort_redmine.users where id=source.value)
and lastname=(select lastname from niort_redmine.users where id=source.value))
where property='attr' and prop_key='assigned_to_id' and source.value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.value=(select id from bitnami_redmine.issue_statuses where name = (select name from niort_redmine.issue_statuses where id=source.value))
where property='attr' and prop_key='status_id' and source.value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.old_value=(select id from bitnami_redmine.issue_statuses where name = (select name from niort_redmine.issue_statuses where id=source.old_value))
where property='attr' and prop_key='status_id' and source.old_value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.old_value=(select id from bitnami_redmine.projects where name=(select name from niort_redmine.projects where id=source.old_value)
and identifier=(select identifier from niort_redmine.projects where id=source.old_value))
where property='attr' and prop_key='project_id' and source.old_value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.value=(select id from bitnami_redmine.projects where name=(select name from niort_redmine.projects where id=source.value)
and identifier=(select identifier from niort_redmine.projects where id=source.value))
where property='attr' and prop_key='project_id' and source.value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.value=(select dest.id from bitnami_redmine.versions dest, niort_redmine.versions source2 where
 dest.name=source2.name and dest.project_id = (select id from bitnami_redmine.projects where
 name = (select name from niort_redmine.projects where id = source2.project_id) and 
 identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and source.value = source2.id)
where property='attr' and prop_key='fixed_version_id' and source.value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.old_value=(select dest.id from bitnami_redmine.versions dest, niort_redmine.versions source2 where
 dest.name=source2.name and dest.project_id = (select id from bitnami_redmine.projects where
 name = (select name from niort_redmine.projects where id = source2.project_id) and 
 identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and source.value = source2.id)
where property='attr' and prop_key='fixed_version_id' and source.old_value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.value=(select id from bitnami_redmine.trackers where name = (select name from niort_redmine.trackers where id = source.value))
where property='attr' and prop_key='tracker_id' and source.value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.old_value=(select id from bitnami_redmine.trackers where name = (select name from niort_redmine.trackers where id = source.old_value))
where property='attr' and prop_key='tracker_id' and source.old_value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.value=(select dest.id from bitnami_redmine.issue_categories dest, niort_redmine.issue_categories source2 where dest.project_id = 
(select id from bitnami_redmine.projects where name = (select name from niort_redmine.projects where id = source2.project_id) and
identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and dest.name=source2.name and source2.id=source.value)
where property='attr' and prop_key='category_id' and source.value IS NOT NULL;
UPDATE niort_redmine.journal_details source
SET source.old_value=(select dest.id from bitnami_redmine.issue_categories dest, niort_redmine.issue_categories source2 where dest.project_id = 
(select id from bitnami_redmine.projects where name = (select name from niort_redmine.projects where id = source2.project_id) and
identifier = (select identifier from niort_redmine.projects where id = source2.project_id)) and dest.name=source2.name and source2.id=source.old_value)
where property='attr' and prop_key='category_id' and source.old_value IS NOT NULL;

UPDATE niort_redmine.journal_details source
SET source.prop_key=(select id from bitnami_redmine.custom_fields where name=(select name from niort_redmine.custom_fields where id=source.prop_key))
where property='cf' and source.prop_key IS NOT NULL;

SET @maxJDetails = (select GREATEST( (select max(id) from bitnami_redmine.journal_details), (select max(id) from niort_redmine.journal_details) ));
UPDATE niort_redmine.journal_details source
SET source.id = source.id + @maxJDetails,
source.journal_id = source.journal_id + @maxIdJournal;

INSERT INTO bitnami_redmine.journal_details SELECT * FROM niort_redmine.journal_details;

-- On remet à NULL les queries que l'on avait modifié dans rectificationsAvant.sql pour permettre la fusion
UPDATE bitnami_redmine.queries
SET project_id = NULL where project_id=(select id from bitnami_redmine.projects where name='[A classer]');

-- On remet à null les champs effective_date de la table Versions que l'on avait modifié pour permettre la fusion
UPDATE bitnami_redmine.versions SET effective_date = NULL WHERE effective_date='2100-01-01';

-- Réactivation de la sécurité
SET SQL_SAFE_UPDATES = 1;