#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP ALL B
# sauvegarde de touts les bases ouvertes (en mode archivelog)
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------

# Nom du fichier .env
ENV_FILE=".env"

# Vérifier si le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : Le fichier $ENV_FILE n'existe pas."
    echo "Erreur : Impossible de charger les variables d'environnement."
    exit 1
fi

# Charger les variables d'environnement depuis le fichier .env
source "$ENV_FILE"


#------------------------------------------------------------------------------
# boucle de sauvegarde des bases
#------------------------------------------------------------------------------
for b in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | sort)
do 
	${SCRIPTS_DIR}/backup_rman.sh $b
done
