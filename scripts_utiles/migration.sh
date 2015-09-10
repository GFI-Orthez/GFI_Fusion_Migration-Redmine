#!/bin/sh

source central

aide(){
	echo -e "\n\n -> Ce script rassemble toutes les actions nécessaires pour une migration vers une version supérieure:\n\n"
	echo -e "-> Installation du gem bundler\n-> Mise à jour de certains gems (voir Gemfile)\n-> Execution de la commande rake db:migrate\n-> Paramètrage de la langue en français\n->Création des nouveaux répertoires tmp/pdf et public/plugin_assets\n\n"
    echo -e "Aucun argument requis\n"
}

migrate(){

	cd ${CHEMIN_RACINE}
	fichierMigration="migration"
	repertoire=$(dirname $(find $PWD -maxdepth 4 -type f -name Gemfile)) # On répcupère le nom du réperoire qui contient le fichier Gemfile (apps/redmine/htdocs pour ensuite lancer les commandes bundle depuis ce répertoire)
	echo "cd ${repertoire};gem install bundler;bundle install --without development test;bundle exec rake generate_secret_token;bundle exec rake db:migrate RAILS_ENV=production;bundle exec rake redmine:load_default_data REDMINE_LANG=fr RAILS_ENV=production;" > ${fichierMigration}
	./${SCRIPT_A_LANCER} < ${fichierMigration}
	rm ${fichierMigration}
	cd ${repertoire}
	mkdir -p tmp tmp/pdf public/plugin_assets
	chown -R ${LOGNAME}:${LOGNAME} files log tmp public/plugin_assets
	chmod -R 755 files log tmp public/plugin_assets
}

if [ "$1" == "-h" ]
then
	aide
elif [ $# == 0 ]
then
	migrate
else
	echo -e "\nAide:		"$0" -h\n"
	echo -e "Exemple:	"$0"\n"
fi

exit 0