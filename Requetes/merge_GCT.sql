-- Fusion des projets "GCT - ACTIVITES INTERNES", "Absences", "Mandat", "Formation", "Divers" de la base source dans ceux de la base destination
-- Leur contenu sera fusionné avec les projets de même nom dans la base destination d'origine
-- Vérifier que ces id correspondent bien aux projets à fusionner dans la base destination
SET SQL_SAFE_UPDATES = 0;

-- Mise à jour table Enumerations
-- Les énumérations qui référencent les projets à supprimer vont maintenant référencer les projets homologues déjà présents dans la base destination
-- le min(id) permet de ne garder que les projets d'origine (qui ont un id plus faible car déjà présents dans la base destination)
UPDATE bitnami_redmine.enumerations source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Documents
UPDATE bitnami_redmine.documents source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Members
UPDATE bitnami_redmine.members source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Journals
UPDATE bitnami_redmine.journals dest
SET dest.journalized_id=(select min(id) from bitnami_redmine.issues
where subject=(select subject from bitnami_redmine.issues where id=dest.journalized_id))
where journalized_id IN
(select id from niort_redmine.issues where project_id IN (1211, 1212, 1213, 1210, 1214));

-- Mise à jour table News
UPDATE bitnami_redmine.news source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Wikis
UPDATE bitnami_redmine.wikis source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);
ALTER IGNORE TABLE bitnami_redmine.wikis ADD UNIQUE INDEX wikis_unique (project_id);
alter table bitnami_redmine.wikis drop index wikis_unique;

-- Mise à jour table Queries
UPDATE bitnami_redmine.queries source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Categories
UPDATE bitnami_redmine.issue_categories source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Issues
UPDATE bitnami_redmine.issues source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);
-- Cetaines demandes sont présentes dans les projets originaux et dans les projets que l'on veut supprimer. Les demandes en double seront supprimées par la suite

-- Mise à jour table Time_entries
-- Requête très longue à effectuer (plusieurs minutes)
UPDATE bitnami_redmine.time_entries source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id)),
source.issue_id=(select min(id) from bitnami_redmine.issues
where subject=(select subject from bitnami_redmine.issues where id=source.issue_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Versions
UPDATE bitnami_redmine.versions source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Enabled_modules
UPDATE bitnami_redmine.enabled_modules source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

-- Mise à jour table Projects
UPDATE bitnami_redmine.custom_fields_projects source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);

alter table bitnami_redmine.projects_trackers drop index projects_trackers_unique;

-- Mise à jour table Projects_trackers
UPDATE bitnami_redmine.projects_trackers source
SET source.project_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.project_id))
where project_id IN (1211, 1212, 1213, 1210, 1214);
ALTER IGNORE TABLE bitnami_redmine.projects_trackers ADD UNIQUE INDEX projects_trackers_unique (project_id, tracker_id);

alter table bitnami_redmine.custom_values drop index custom_values_unique;

-- Modification des custom_values qui référencent les issues à supprimer
UPDATE bitnami_redmine.custom_values dest
SET dest.customized_id=(select min(id) from bitnami_redmine.issues
where subject=(select subject from bitnami_redmine.issues where id=dest.customized_id))
where customized_type='Issue' and customized_id IN (select id from bitnami_redmine.issues where project_id IN (1211, 1212, 1213, 1210, 1214));

UPDATE bitnami_redmine.custom_values source
SET source.customized_id=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.customized_id))
where customized_type='Project' and customized_id IN (1211, 1212, 1213, 1210, 1214);

ALTER IGNORE TABLE bitnami_redmine.custom_values ADD UNIQUE INDEX custom_values_unique (customized_type, customized_id, custom_field_id);

UPDATE bitnami_redmine.journal_details source
SET source.old_value=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.old_value))
where prop_key='project_id' and old_value IN (1211, 1212, 1213, 1210, 1214);

UPDATE bitnami_redmine.journal_details source
SET source.value=(select min(id) from bitnami_redmine.projects where name =(select name from bitnami_redmine.projects where id=source.value))
where prop_key='project_id' and old_value IN (1211, 1212, 1213, 1210, 1214);

-- Phase de suppression
-- Suppression des issues qui référençaient les projets à supprimer (elles référencent maintenant les bon projets mais sont devenues des doublons)
-- Le having count(*)>1 permet de ne selectionner que les issues qui présentes un doublon
-- Le max(id) permet de ne selectionner que les issues doublons (elles ont des id plus élevés car elles ont été importées depuis la base source)
DELETE from bitnami_redmine.issues where id IN (
select * from (select max(id) from bitnami_redmine.issues
where subject IN (select subject from niort_redmine.issues where project_id IN (1211, 1212, 1213, 1210, 1214))
group by subject having count(*)>1) as p
);

-- Mise à jour des Issues qui n'étaient pas en double
-- Certaines demandes étaient présentes dans la base source mais pas dans la base destination. Il ne faut pas les supprimer.
-- Il s'agit de la demande "Formation donnée"
UPDATE bitnami_redmine.issues dest
SET dest.project_id = (select min(id) from bitnami_redmine.projects where name=(select name from bitnami_redmine.projects where id=dest.project_id))
where subject IN (select subject from niort_redmine.issues where project_id IN (1211, 1212, 1213, 1210, 1214));

-- On supprime les projets doublons que l'on vient de fusionner
DELETE from bitnami_redmine.projects where id IN (1211, 1212, 1213, 1210, 1214);

-- On réactive la sécurité
SET SQL_SAFE_UPDATES = 1;