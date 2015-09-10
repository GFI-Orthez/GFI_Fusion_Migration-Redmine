#!/bin/sh

# Permet la sauvegarde et/ou la restauration d'une base de données

source central
nbParamsautorises=0

aide(){
	echo -e " ->Ce script permet de convertir l'encodage des données et de la base.\nConversion effectuée: latin1->utf8\nCe script ne prend aucun paramètre\n"
}

encode(){
cd ${CHEMIN_RACINE}

tmp="tmp"
dump_orig="dump.sql"
dump_utf8="dump_utf8.sql"

echo "mysqldump -u${USER_ROOT} -p${PASSWORD_ROOT} -c -e --default-character-set=latin1 --single-transaction --skip-set-charset --add-drop-database -B ${BASEDEST} > ${dump_orig};
sed 's/DEFAULT CHARACTER SET latin1/DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci/' < ${dump_orig} | sed 's/DEFAULT CHARSET=latin1/DEFAULT CHARSET=utf8/' > ${dump_utf8};
mysql -u${USER_ROOT} -p${PASSWORD_ROOT} -e 'DROP DATABASE bitnami_redmine';
mysql -u${USER_ROOT} -p${PASSWORD_ROOT} -e 'CREATE DATABASE bitnami_redmine CHARACTER SET utf8 COLLATE utf8_general_ci';
mysql -u${USER_ROOT} -p${PASSWORD_ROOT} < ${dump_utf8};exit;" > ${tmp}
./${SCRIPT_CONTROL} start mysql

echo -e "\nModification de l'encodage des données et de la base...\n"
./${SCRIPT_A_LANCER} < ${tmp}

rm ${tmp}
rm ${dump_orig}
rm ${dump_utf8}

echo -e "Redémarrage du serveur MySQL...\n"
./${SCRIPT_CONTROL} restart mysql

echo -e "Terminé\n"
}


if [ "$1" == "-h" ]
then
	echo -e "\nAide"
	aide
elif [ ${nbParamsautorises} -ne $# ]
then
	echo -e "\n\n	Il faut passer "${nbParamsautorises}" parametre(s)"
	echo -e "Exemple :	"$0"\n\n"
else
	encode
fi

exit 0