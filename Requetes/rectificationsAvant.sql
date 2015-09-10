-- Script de rectifications de bases de données Redmine dans le but de les fusionner ultérieurement
-- Ces rectifications sont à double but : 
-- 		1) Permettre la fusion (sans ces modifications le plugin de fusion s'arrete en cours d'exécution)
-- 		2) Nettoyer au mieux les bases

-- Ici la base source se nomme 'niort_redmine' et la base destination se nomme 'bitnami_redmine'
-- Les modifications apportées ici sont propres à l'état de ces bases à l'heure actuelle (entre Mars 2015 et Juin 2015)
-- Ce qui suit est à modifier en fonction de l'état des bases qui seront à fusionner

-- A EFFECTUER AVANT LA FUSION DE LA PREMIERE TABLE !!

--  On desactive le safe update mode pour pouvoir effectuer des updates sur toute une table sans condition
SET SQL_SAFE_UPDATES = 0;

-- Les dates nulles ne sont pas prises en compte dans le plugin. On affecte une date à toutes les lignes dont le champ effective_date est NULL (on les remettra à NULL après)
UPDATE niort_redmine.versions SET effective_date = '2100-01-01' WHERE effective_date IS NULL;

-- L'utilisateur chuckert possède deux comptes mais son login dans la base destination n'est pas correct
UPDATE bitnami_redmine.users SET login = 'chuckert' where id = 46;

-- On modifie les identifiants des projets qui sont existent sur les deux bases (cet identifiant doit être unique)
UPDATE niort_redmine.projects
SET identifier=concat(identifier, '2')
where identifier IN (select identifier from bitnami_redmine.projects);

-- On identifie les trackers et le projets qui sont associés et qui ne sont pas contenus dans la table projects_trackers 
insert into niort_redmine.projects_trackers
select i.project_id, i.tracker_id
from niort_redmine.issues i
where concat(i.project_id, ' ', i.tracker_id) not in (
select concat(project_id,' ',tracker_id)
from niort_redmine.projects_trackers
order by 1)
group by i.project_id, i.tracker_id;

-- On associe à un utilisateur les requêtes qui étaient associées à l'utilsiateur anonyme
update niort_redmine.issues set assigned_to_id=4 where assigned_to_id=2;

-- Certaines demandes (issues) ne références aucun projet. On crée donc un projet de remplacement qui va uniquement servir à éviter d'avoir une référence nulle vers un projet.
SET @maxIDProject=(select max(id) +1 from niort_redmine.projects);
insert into niort_redmine.projects
(id, name, is_public, identifier, status)
values
( @maxIDProject, '[A classer]', 0, 'a-classer', 1);

-- Puis on affecte ces demandes à ce nouveau projet
update niort_redmine.issues
set project_id= (@maxIDProject)
where project_id not in (
        select id
        from niort_redmine.projects
        order by id
);

-- Ainsi que les trackers associés
insert into niort_redmine.projects_trackers
select project_id, tracker_id
from niort_redmine.issues
where project_id= (@maxIDProject)
group by project_id, tracker_id;


-- Certaines données de la table time_entries ne référencent aucun projet
-- On affecte donc ces données au nouveau projet crée précédemment
update niort_redmine.time_entries
set project_id=@maxIDProject
where project_id is not null
and project_id not in (
select id
from niort_redmine.projects
order by id
);

-- Resplan n'autorise pas certains caractères. S'ils sont présent dans la table time_entries, la fusion plante.
-- On supprime donc toutes les occurences de ces caratères dans les données de la table time_entries
update niort_redmine.time_entries
set comments=replace(replace(
replace(replace(
replace(replace(
replace(comments,'\'', ' ')
, '"', ' '), '#', ' ')
, '&', ' '), '*', ' ')
, '?', ' '), '%', ' ')
where comments regexp '[&*%?\'#"]';


-- On crée une nouvelle activité dans le but d'y associer des données de la table time_entries (on récupère pour cela l'id max de la table)
SET @maxIDEnum=(select max(id) +1 from niort_redmine.enumerations);
insert into niort_redmine.enumerations(id, name, position,
is_default, type, active)
values (@maxIDEnum, 'A qualifier', 31, 0, 'TimeEntryActivity', 1);

-- On associe les time_entries dont l'activité est 1 à cette nouvelle activité
update niort_redmine.time_entries
set activity_id=@maxIDEnum
where activity_id=1;

-- Modification dans la base source car doublon avec la base destinaton
update niort_redmine.time_entries
set gct_tpscra='S'
where user_id=37
and spent_on='2014-09-01';

-- On supprime les doublons dans la base source
delete from niort_redmine.time_entries
where id in (27745, 27753, 27755, 27757, 27759, 27760, 27761, 27762,
27763, 27764, 27765, 27767, 27769, 27774, 27776, 27778, 27779,
27780, 27782, 27784, 27785, 27786, 27787);

-- Ces valeurs d'id ont été trouvées grace à la requete suivante (trop longue à exécuter)
/*
select two.id
from niort_redmine.time_entries one, niort_redmine.time_entries two
where one.id < two.id
and one.user_id=two.user_id
and one.spent_on=two.spent_on
and one.gct_tpscra=two.gct_tpscra
and (one.gct_tpscra != '' and one.gct_tpscra != 'A');
*/

-- On supprime les doublons dans la base source
delete from niort_redmine.time_entries
where id in (27742);

-- Cet id a été trouvé grace à la requete suivante (trop longue à exécuter)
/*
select nt.id, nt.project_id, nt.user_id, nu.login, nt.activity_id,
nt.spent_on, nt.gct_tpscra, nt.comments,
ot.id, ot.project_id, ot.user_id, ou.login, ot.activity_id,
ot.spent_on, ot.gct_tpscra, ot.comments
from niort_redmine.time_entries nt, bitnami_redmine.time_entries ot,
niort_redmine.users nu, bitnami_redmine.users ou
where nt.user_id=nu.id
and ot.user_id=ou.id
and nu.login=ou.login
and nt.spent_on = ot.spent_on
and nt.gct_tpscra = ot.gct_tpscra
order by nt.id;
*/

-- On supprime la colonne 'user_story_id` de la table issues qui fait planter la fusion
ALTER TABLE `bitnami_redmine`.`issues`
DROP COLUMN `user_story_id`;

-- On rajoute un lien entre un projet et un tracker qui n'est pas présent dans la table project_trackers
insert into bitnami_redmine.projects_trackers values (242, 37);

-- On associe à l'utilisateur anonyme toutes les requêtes qui référençaient l'utilisateur ayant l'id 0 (qui n'existe pas)
update niort_redmine.queries
set user_id=2
where user_id=0;

-- Pour les lignes qui référencent un projet qui n'existe pas, on leur associe le project que l'on vient de créer
update niort_redmine.enabled_modules
set project_id=(select id from niort_redmine.projects where name='[A classer]')
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

update niort_redmine.queries
set project_id=(select id from niort_redmine.projects where name='[A classer]')
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

update niort_redmine.issues
set project_id=(select id from niort_redmine.projects where name='[A classer]')
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

update niort_redmine.time_entries
set project_id=(select id from niort_redmine.projects where name='[A classer]')
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

update niort_redmine.members
set project_id=(select id from niort_redmine.projects where name='[A classer]')
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

-- Certaines tables possèdent des contraintes d'unicité (donc on ne peut pas faire l'association avec le projet que l'on vient de créer)
-- Dans ce cas, il faut les supprimer (ou alors désactiver la contrainte, faire l'association et réactiver la contrainte)
delete from niort_redmine.projects_trackers
where project_id in  (6, 8, 13, 14, 15, 16);

Delete from niort_redmine.wikis
where project_id in (6, 8, 13, 14, 15, 16) or project_id IS NULL;

DELETE from niort_redmine.custom_values where customized_type='Project' and customized_id IN (6, 8, 13, 14, 15, 16);


-- Les deux procédures suivantes permettent de fusionner les listes de valeurs possibles pour les équipes et les types de projets
-- Ces listes sont différentes et certaines valeurs dans ces listes ne sont pas fusionnées (seules celles présentes dans la base destination sont présentes au final)
-- Ces procédures règlent le problème en fusionnant les deux listes pour obtenir toutes les valeurs dans la base fusionnée.

use bitnami_redmine;

-- On concatene la liste des équipes. Les équipes de la base source qui ne sont pas présentes dans la base destination sont importées.
DROP PROCEDURE IF EXISTS concatenation_listeUser;

DELIMITER //
CREATE PROCEDURE concatenation_listeUser()
BEGIN
	DECLARE compteur  INT;
	DECLARE total  INT;
	DECLARE chaine  VARCHAR(255);
	DECLARE boo  INT;
    SET compteur=0;
    SET total= (SELECT    ROUND ((LENGTH(possible_values)- LENGTH( REPLACE ( possible_values, "- ", "") )) / LENGTH("- "))-1
		FROM niort_redmine.custom_fields
		WHERE type='UserCustomField' and name='Equipe');
	WHILE compteur<total DO
		SET compteur=compteur+1;
        SET chaine=(SELECT substring_index(substring_index(possible_values, '- ', -compteur),
                       '\n', 1) FROM niort_redmine.custom_fields where type='UserCustomField' and name='Equipe');
		SET boo=(SELECT count(possible_values) FROM bitnami_redmine.custom_fields
		WHERE type='UserCustomField' and name='Equipe' and INSTR(possible_values, chaine) > 0);
		
        IF boo=0 THEN
			UPDATE bitnami_redmine.custom_fields
			SET possible_values=concat(possible_values, '- ', chaine, '\n')
			WHERE type='UserCustomField' and name='Equipe';
        END IF;
  END WHILE;
END //
DELIMITER ;

-- On concatene la liste des types de projets possibles. Les valeurs possibles de la base source qui ne sont pas déjà présentes dans la base destination sont importées.
DROP PROCEDURE IF EXISTS concatenation_listeProjet;
DELIMITER //
CREATE PROCEDURE concatenation_listeProjet()
BEGIN
	DECLARE compteur  INT;
	DECLARE total  INT;
	DECLARE chaine  VARCHAR(255);
	DECLARE boo  INT;
    SET compteur=0;
    SET total= (SELECT    ROUND ((LENGTH(possible_values)- LENGTH( REPLACE ( possible_values, "- ", "") )) / LENGTH("- "))-1
		FROM niort_redmine.custom_fields
		WHERE type='ProjectCustomField' and name='Type Projet');
	WHILE compteur<total DO
		SET compteur=compteur+1;
        SET chaine=(SELECT substring_index(substring_index(possible_values, '- ', -compteur),
                       '\n', 1) FROM niort_redmine.custom_fields where type='ProjectCustomField' and name='Type Projet');
		SET boo=(SELECT count(possible_values) FROM bitnami_redmine.custom_fields
		WHERE type='ProjectCustomField' and name='Type Projet' and INSTR(possible_values, chaine) > 0);
		
        IF boo=0 THEN
			UPDATE bitnami_redmine.custom_fields
			SET possible_values=concat(possible_values, '- ', chaine, '\n')
			WHERE type='ProjectCustomField' and name='Type Projet';
        END IF;
  END WHILE;
END //
DELIMITER ;

CALL concatenation_listeUser();
DROP PROCEDURE IF EXISTS concatenation_listeUser;


CALL concatenation_listeProjet();
DROP PROCEDURE IF EXISTS concatenation_listeProjet;

-- Réactivation de la sécurité
SET SQL_SAFE_UPDATES = 1;

-- Ensuite il suffit d'effectuer la fusion...
