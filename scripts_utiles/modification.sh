#!/bin/sh

# Ce script permet de remplacer les ports utilisés par les serveurs Apache, Redmine (Passenger), MySQL et subversion par de nouveaux ports définis dans le fichier central.
# Il permet aussi de mettre à jour les fichiers database.yml et configuration.yml.
# Attention ! Vérifier que les nouveaux ports définis dans le fichier central soient accessibles à travers le pare-feu

# Ce script permet de remplacer les ports par défaut par les nouveaux ports. On ne peut donc pas exécuter ce script deux fois consécutives avec des ports différents.
# Pour cela, si les nouveaux ports doivent encore être modifiés. Il est possible de rétablir les ports par défaut à l'aide de l'option --default.
# Une fois les ports par défaut rétablis, il est possible de réexécuter le script pour les mettre à jour.

source central

nbParamsautorises=1

port_apache_new=${portApache}
port_MySQL_new=${portMySQL}
port_redmine1_new=${portRedmine1}
port_redmine2_new=${portRedmine2}
port_subversion_new=${portSubversion}

port_apache_old=${portApacheDefaut}
port_MySQL_old=${portMySQLDefaut}
port_redmine1_old=${portRedmine1Defaut}
port_redmine2_old=${portRedmine2Defaut}
port_subversion_old=${portSubversionDefaut}

fichier_apache=${fichierApache}
fichier_redmine=${fichierRedmine}
fichier_MySQL1=${fichierMySQL1}
fichier_MySQL2=${fichierMySQL2}
fichier_subversion=${fichierSubversion}
fichier_bitnami=${fichierBitnami}

user=${USER}
pwd=${PASSWORD_USER}

aide(){
    echo -e "\n\n -> Ce script permet de mettre à jour les ports relatifs aux serveurs Apache, Redmine, MySQL et Subversion\n\n"
    echo -e "L'option --default permet de rétablir les valeurs par défaut des ports\n"
}


modification(){
	cd ${CHEMIN_RACINE}

	# ***Modification port Apache***
	echo -e "Modification du port Apache :\nAncien port ${port_apache_old}\nNouveau port ${port_apache_new}\n\n"
	cheminFichierApache=$(find $PWD -type f -name ${fichier_apache} | head -n 1) # Fichier httpd.conf
	sed -i "s/${port_apache_old}/${port_apache_new}/g" ${cheminFichierApache}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${fichier_apache}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi
	cheminFichierBitnami=$(find $PWD -type f -name ${fichier_bitnami} | head -n 1) # Fichier bitnami.conf
	sed -i "s/${port_apache_old}/${port_apache_new}/g" ${cheminFichierBitnami}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierBitnami}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi

	# ***Modification ports Redmine (Passenger)***
	cheminFichierRedmine=$(find $PWD -type f -name ${fichier_redmine} | head -n 1) # Fichier redmine.conf
	sed -i "s/${port_apache_old}/${port_apache_new}/g" ${cheminFichierRedmine}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierRedmine}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi
	# On n'utilise pas les ports Redmine (3101 et 3102) car à partir de maintenant Redmine est relié à Apache. Le démarrage du serveur Apache entraine le lancement des serveurs Redmine (ce qui n'est psa le cas dans la version 1.0.0)

	# ***Modifier le fichier database.yml***
	echo -e "Modification du fichier database.yml\n\n"
	cd ${CHEMIN_RAKE}
	
	cheminFichierDatabase=$(find $PWD -maxdepth 3 -type f -name ${NOM_FICHIER} | head -n 1) #On se limite à 3 niveaux de profondeur car des fichiers database.yml sont aussi présents dans lib/...
	#On modifie juste le mot de passe et le nom d'utilisateur de la base de production
	sed -i "0,/^.*\busername\b.*$/s//  username: ${user}/" ${cheminFichierDatabase}
	sed -i "0,/^.*\bpassword\b.*$/s//  password: ${pwd}/" ${cheminFichierDatabase}
	sed -i "0,/^.*\bdatabase\b.*$/s//  database: ${BASEDEST}/" ${cheminFichierDatabase}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierDatabase}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi

	# ***Modification port MySQL***
	echo -e "Modification du port MySQL :\nAncien port ${port_MySQL_old}\nNouveau port ${port_MySQL_new}\n\n"
	# On descend d'un niveau car un des fichiers mysql possède le même nom qu'un des fichiers de Subversion (ctl.sh)
	# De cette manière, la commande find renverra le résultat souhaité dans les deux cas
	cd ${CHEMIN_RACINE}"/mysql"

	cheminFichierMySQL1=$(find $PWD -type f -name ${fichier_MySQL1} | head -n 1) # Fichier my.cnf
	sed -i "s/${port_MySQL_old}/${port_MySQL_new}/g" ${cheminFichierMySQL1}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierMySQL1}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi

	cheminFichierMySQL2=$(find $PWD -type f -name ${fichier_MySQL2} | head -n 1) # Fichier ctl.sh
	sed -i "s/${port_MySQL_old}/${port_MySQL_new}/g" ${cheminFichierMySQL2}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierMySQL2}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi
	# ***Modification port Subversion***
	echo -e "Modification du port Subversion :\nAncien port ${port_subversion_old}\nNouveau port ${port_subversion_new}\n\n"
	cd ${CHEMIN_RACINE}"/subversion"
	cheminFichierSubversion=$(find $PWD -type f -name ${fichier_subversion} | head -n 1) # Fichier ctl.sh
	sed -i "s/${port_subversion_old}/${port_subversion_new}/g" ${cheminFichierSubversion}
	if [ "$?" = "1" ]; then
		echo -e "Une erreur s'est produite lors de l'écriture dans le fichier ${cheminFichierSubversion}.\n-> Vérifier que le fichier existe|n-> Vérifier que vous avez les droits d'écriture et de lecture\n"
		exit 1
	fi
	# ***Editer le fichier configuration.yml***
	echo -e "Modification du fichier configuration.yml\n\n"
	cd ${CHEMIN_RAKE}
	cheminConfig=$(find $PWD -maxdepth 2 -type d -name 'config' | head -n 1) # Fichier configuration.yml
	cd ${cheminConfig}
	echo -e "Si cette étape est trop longue, vérifier que les fichiers email.yml et configuration.yml sont présents dans le répertoire ${cheminConfig}\n"
	cheminFichierConfiguration=$(find $PWD -type f -name ${FICHIER_CONFIGURATION} | head -n 1)
	cheminFichierMail=$(find $PWD -type f -name ${FICHIER_MAIL} | head -n 1) # Fichier email.yml (qui a été copié depuis le redmine 1.0.0)

	head -n -5 ${cheminFichierConfiguration} > tmpo1
	mv ${cheminFichierConfiguration} ${cheminFichierConfiguration}".example"
	cat tmpo1 ${cheminFichierMail} > ${FICHIER_CONFIGURATION}
	if [ "$?" = "1" ]; then
		echo -e "Erreur : Le fichier de configuration n'a pas pu être généré\n-> Vérifier que le fichier email.yml existe bien\n"
		exit 1
	fi
	rm tmpo1
	rm ${cheminFichierMail}
}

default(){
	#On inverse les variables avant d'effectuer la modification
	port_apache_new=${portApacheDefaut}
	port_MySQL_new=${portMySQLDefaut}
	port_redmine1_new=${portRedmine1Defaut}
	port_redmine2_new=${portRedmine2Defaut}
	port_subversion_new=${portSubversionDefaut}

	port_apache_old=${portApache}
	port_MySQL_old=${portMySQL}
	port_redmine1_old=${portRedmine1}
	port_redmine2_old=${portRedmine2}
	port_subversion_old=${portSubversion}
	
	echo -e "Rétablissement des valeurs par défaut des ports\n\n"
}

if [ "$1" == "-h" ]
then
	aide
elif [ "$1" == "--default" ]
then
	default
	modification
elif [ $# == 0 ]
then
	modification
else
	echo -e "\nAide:		"$0" -h\n"
	echo -e "\nExemple:	"$0"\n"
	echo -e "\nExemple pour rétablir les valeurs par défaut:	"$0" --default\n"
fi


exit 0