#!/bin/sh

source central

aide(){
    echo -e "\n\n -> Ce script de modifier la base ${BASEDEST} en supprimant des tables vides qui empêchent la migration\net en garantissant l'accès à cette base à l'utilisateur ${USER}\n\n"
    echo -e "L'option --no-start permet de s'affranchir de la mise en marche du serveur MySQL.\nCette étape est légèrement longue et peut ainsi être évitée s'il est déjà en marche.\n"
	echo -e "Attention: En utilisant cette option, il faut s'assurer que le serveur MySQL est en marche\n \n"
}

preparation(){
	#Création du nouvel utilisateur bitnami
	cd ${CHEMIN_RACINE}
	fichierMySQL="connexion"
	commandeMySQL="commande"
	echo "DROP USER '${USER}'@'localhost'; CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASSWORD_USER}'; GRANT ALL PRIVILEGES ON ${BASEDEST}.* to '${USER}'@'localhost'; flush privileges;"  >  "${commandeMySQL}"
	echo "mysql -u ${USER_ROOT} -p${PASSWORD_ROOT} < ${commandeMySQL}; exit; "  > ${fichierMySQL}
	echo -e "\n->Création de l'utilisateur ${USER}\n->Attribution des droits sur la table ${BASEDEST}\n"
	./${SCRIPT_A_LANCER} < ${fichierMySQL}
	if [ "$?" = "1" ]; then
		echo -e "Erreur : Impossible d'effectuer les modifications SQL:\n-> Vérifier que le port relatif à MySQL est ouvert : ${portMySQL} ou ${portMySQLDefaut}\n-> Vérifier que l'utilisateur ${USER} existe bien avant de lancer ce script\n-> Vérifier les mots de passe et noms d'utilisateur dans le script central\n"
		exit 1
	fi
	rm ${commandeMySQL}
	rm ${fichierMySQL}
	
	#On restore la base récupérée sur la version 1.0.0
	cd ${CHEMIN_SCRIPTS}
	./${SCRIPT_SAVE_RESTORE} -r ${USER} ${BASEDEST} 
	if [ "$?" = "1" ]; then
		echo -e "Erreur : Impossible de restorer la dernière sauvegarde\n"
		exit 1
	fi
	# Suppression des tables vides qui font échouer la migration
	cd ${CHEMIN_RACINE}
	fichierMYSQL2="connexion2"
	commandeMySQL2="commande2"
	echo -e "\n->Suppression des tables vides qui empêchent la migration\n\n"
	echo "DROP TABLE IF EXISTS changeset_parents, queries_roles, custom_fields_roles, email_addresses, roles_managed_roles;" > ${commandeMySQL2}
	echo "mysql -u ${USER} -p${PASSWORD_USER} ${BASEDEST} < ${commandeMySQL2};exit;  " > ${fichierMYSQL2}
	./${SCRIPT_A_LANCER} < ${fichierMYSQL2}
	rm ${fichierMYSQL2}
	rm ${commandeMySQL2}
	cd ${CHEMIN_SCRIPTS}
}

if [ "$1" == "-h" ]
then
	aide
elif [ "$1" == "--no-start" ]
then
	preparation
elif [ $# == 0 ]
then
	cd ${CHEMIN_RACINE}
	./${SCRIPT_CONTROL} restart mysql
	preparation
else
	echo -e "\nAide:		"$0" -h\n"
	echo -e "Exemple:	"$0"\n"
	echo -e "Exemple sans démarrer MySQL:	"$0" --no-start\n"
fi

exit 0